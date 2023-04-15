import Foundation
import AVFoundation

let input = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[1])
let output = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[2])

do {
	let reader = try! AVAudioFile(forReading: input)
	let writer = try! AVAudioFile(forWriting: output, settings: [
		AVFormatIDKey: kAudioFormatFLAC,
		AVNumberOfChannelsKey: reader.processingFormat.settings[AVNumberOfChannelsKey]!,
		AVSampleRateKey: reader.processingFormat.settings[AVSampleRateKey]!
	])

	let buffer = AVAudioPCMBuffer(pcmFormat: reader.processingFormat, frameCapacity: 1024 * 1024)!

	while reader.framePosition < reader.length {
		buffer.frameLength = 0
		try! reader.read(into: buffer)
		try! writer.write(from: buffer)
	}
}
