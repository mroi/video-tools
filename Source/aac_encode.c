/* QuickTime AAC encoder code based on libhb from the HandBrake project */

#include <AudioToolbox/AudioToolbox.h>
#include <CoreAudio/CoreAudio.h>
#include <CoreFoundation/CFURL.h>

#include <stdio.h>
#include <string.h>
#include <sysexits.h>

#define CHECK(X) if ((X) != noErr) return EX_UNAVAILABLE;


static void *buffer = NULL;

static OSStatus input_callback(AudioConverterRef converter, UInt32 *numPackets,
                               AudioBufferList *bufferList, AudioStreamPacketDescription **desc,
                               void *unused)
{
	(void)converter;
	(void)desc;
	(void)unused;
	
	/* this gets called by the converter when it needs data */
	size_t size = *numPackets * 4;
	
	buffer = realloc(buffer, size);
	size = fread(buffer, 1, size, stdin);
	
	if (size == 0) {
		*numPackets = 0;
	} else {
		bufferList->mBuffers[0].mNumberChannels = 2;
		bufferList->mBuffers[0].mDataByteSize = (UInt32)size;
		bufferList->mBuffers[0].mData = buffer;
		*numPackets = (UInt32)(size / 4);
	}
	
	return noErr;
}


int main(int argc, const char **argv)
{
	AudioStreamBasicDescription input, output;
	AudioConverterRef converter;
	AudioFileID outfile;
	UInt32 maxsize;
	
	if (argc != 2) {
		fprintf(stderr, "Usage: aac_encode <output file name>\n");
		return EX_USAGE;
	}
	
	/* setup input format */
	bzero(&input, sizeof(AudioStreamBasicDescription));
	input.mSampleRate = (Float64)48000.0;
	input.mFormatID = kAudioFormatLinearPCM;
	input.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian;
	input.mBytesPerPacket = 4;
	input.mFramesPerPacket = 1;
	input.mBytesPerFrame = 4;
	input.mChannelsPerFrame = 2;
	input.mBitsPerChannel = 16;
	
	/* setup output format */
	bzero(&output, sizeof(AudioStreamBasicDescription));
	output.mFormatID = kAudioFormatMPEG4AAC;
	output.mSampleRate = (Float64)48000.0;
	output.mChannelsPerFrame = 2;
	
	/* create the audio converter */
	CHECK(AudioConverterNew(&input, &output, &converter));
	
	/* set conversion parameters */
	UInt32 tmp = kAudioConverterQuality_Max;
	CHECK(AudioConverterSetProperty(converter, kAudioConverterCodecQuality,
									sizeof(tmp), &tmp));
	tmp = kAudioCodecBitRateControlMode_VariableConstrained;
	CHECK(AudioConverterSetProperty(converter, kAudioCodecPropertyBitRateControlMode,
									sizeof(tmp), &tmp));
	tmp = 128 * 1000;
	CHECK(AudioConverterSetProperty(converter, kAudioConverterEncodeBitRate,
									sizeof(tmp), &tmp));

	/* get actual format descriptors */
	tmp = sizeof(input);
	AudioConverterGetProperty(converter, kAudioConverterCurrentInputStreamDescription,
							  &tmp, &input);
	tmp = sizeof(output);
	AudioConverterGetProperty(converter, kAudioConverterCurrentOutputStreamDescription,
							  &tmp, &output);
	
	/* create output file */
	CFURLRef url = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)argv[1],
														   (CFIndex)strlen(argv[1]), false);
	CHECK(AudioFileCreateWithURL(url, kAudioFileAAC_ADTSType, &output,
								 kAudioFileFlags_EraseFile, &outfile));
	CFRelease(url);
	
	/* get conversion cookie (header info) and pass to output file */
	CHECK(AudioConverterGetPropertyInfo(converter, kAudioConverterCompressionMagicCookie,
										&tmp, NULL));
	char *cookie = malloc(tmp);
	CHECK(AudioConverterGetProperty(converter, kAudioConverterCompressionMagicCookie,
									&tmp, cookie));
	CHECK(AudioFileSetProperty(outfile, kAudioFilePropertyMagicCookieData, tmp, cookie));
	free(cookie);
	
	/* get maximum output packet size */
	tmp = sizeof(maxsize);
	CHECK(AudioConverterGetProperty(converter, kAudioConverterPropertyMaximumOutputPacketSize,
									&tmp, &maxsize));
	
	/* setup buffer for conversion */
	AudioStreamPacketDescription desc = { 0 };
	AudioBufferList bufferList;
	bufferList.mBuffers[0].mData = malloc(maxsize);
	UInt32 numPackets;
	SInt64 outputPos = 0;
	
	/* pull data out of the converter and write to file */
	do {
		numPackets = 1;
		bufferList.mNumberBuffers = 1;
		bufferList.mBuffers[0].mNumberChannels = 2;
		bufferList.mBuffers[0].mDataByteSize = maxsize;
		CHECK(AudioConverterFillComplexBuffer(converter, input_callback, NULL,
											  &numPackets, &bufferList, &desc));
		CHECK(AudioFileWritePackets(outfile, false, bufferList.mBuffers[0].mDataByteSize, &desc,
									outputPos, &numPackets, bufferList.mBuffers[0].mData));
		outputPos += numPackets;
	} while (numPackets);
	
	/* cleanup */
	AudioConverterDispose(converter);
	AudioFileClose(outfile);
	free(bufferList.mBuffers[0].mData);
	free(buffer);
	
	return EX_OK;
}
