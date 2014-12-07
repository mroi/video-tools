#!/bin/bash

# be conservative: bail out on any error
set -e

# you can put the tools next to the script
PATH="`perl -e 'use File::Basename; use Cwd "abs_path";print dirname(abs_path($ARGV[0]));' "$0"`:$PATH"

HANDBRAKE_320='--width 320 --denoise strong --start-at frame:5'
HANDBRAKE_640='--width 640'
HANDBRAKE_960='--large-file --width 960'
HANDBRAKE_1280='--large-file --width 1280'
HANDBRAKE_1920='--large-file --width 1920'

HANDBRAKE_VIDEO='--encoder x264 --quality 23 --format mp4 --modulus 2'
HANDBRAKE_AUDIO_AAC='--aencoder ca_aac          --ab 128      --arate 48      --mixdown dpl2'
HANDBRAKE_AUDIO_AC3='--aencoder ca_aac,copy:ac3 --ab 128,auto --arate 48,auto --mixdown dpl2,auto'

HANDBRAKE_X264_IPOD='--x264-preset slower --h264-profile baseline --h264-level 3.0'
HANDBRAKE_X264_ATV1='--x264-preset slower --h264-profile main     --h264-level 3.1 --encopts cabac=0:ref=2:bframes=8:b-pyramid=none:weightb=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500'
HANDBRAKE_X264_ATV3='--x264-preset slower --h264-profile high     --h264-level 4.0'

# defaults
audio=1
crop=''
mode=''
options=''
pulldown=''
source=''
stem=''

# parse command  line
for command ; do
	case "$command" in
		[0-9]|[0-9],[0-9])
			audio="$command" ;;
		*:*:*:*)
			crop="$command" ;;
		320)
			mode=320 ;;
		640)
			mode=640 ;;
		960)
			mode=960 ;;
		1280)
			mode=1280 ;;
		1920)
			mode=1920 ;;
		-*)
			options="$options $command" ;;
		*-*)
			pulldown="$command" ;;
		*)
			source="$command" ;;
	esac
done

if ! test "$source" -a "$mode" ; then
	echo "Usage: $(basename "$0") [cropping] [audio channel(s)] [pulldown] [options] 320|640|960|1280|1920 <video>"
	echo
	echo '[cropping]             is of the form <top>:<bottom>:<left>:<right>'
	echo '[audio channel(s)]     is <num> or <num>,<num>; use the latter to add AC3'
	echo '[pulldown]             is <from>-<to> and specifies a framerate conversion'
	echo '[options]              other options to pass to HandBrake'
	echo '320|640|960|1280|1920  the desired image width; height depends on cropping'
	echo '<video>                the source video file'
	exit 1
fi

stem="${source%.*}"
test "$source" = "${stem}.eyetv" && source="`echo "$source"/*.mpg`"
stem="${stem##*/}"

# prepare for pulldown after the encode
case "$pulldown" in
	'')
		;;
	25-24)
		HANDBRAKE_VIDEO="$HANDBRAKE_VIDEO --rate 25"
		# we will generate the AAC track after pulldown
		# FIXME: 25-24 pulldown therefore only works for sources with an AC3 track
		audio=${audio##[0-9],}
		HANDBRAKE_AUDIO_AAC='--aencoder copy:ac3'
		;;
	*)
		echo 'This pulldown is not supported.'
		exit 1
		;;
esac

# set encoding options according to the mode
case "$mode" in
	320)
		case $audio in
			# only AAC audio allowed
			[0-9],[0-9]) audio=${audio%,[0-9]} ;;
		esac
		HANDBRAKE_OPTIONS="$HANDBRAKE_320 $HANDBRAKE_VIDEO $HANDBRAKE_AUDIO_AAC $HANDBRAKE_X264_IPOD" ;;
	640)
		case $audio in
			# only AAC audio allowed
			[0-9],[0-9]) audio=${audio%,[0-9]} ;;
		esac
		HANDBRAKE_OPTIONS="$HANDBRAKE_640 $HANDBRAKE_VIDEO $HANDBRAKE_AUDIO_AAC $HANDBRAKE_X264_IPOD" ;;
	960)
		case $audio in
			[0-9]) HANDBRAKE_AUDIO="$HANDBRAKE_AUDIO_AAC" ;;
			[0-9],[0-9]) HANDBRAKE_AUDIO="$HANDBRAKE_AUDIO_AC3" ;;
		esac
		HANDBRAKE_OPTIONS="$HANDBRAKE_960 $HANDBRAKE_VIDEO $HANDBRAKE_AUDIO $HANDBRAKE_X264_ATV1" ;;
	1280)
		case $audio in
			[0-9]) HANDBRAKE_AUDIO="$HANDBRAKE_AUDIO_AAC" ;;
			[0-9],[0-9]) HANDBRAKE_AUDIO="$HANDBRAKE_AUDIO_AC3" ;;
		esac
		HANDBRAKE_OPTIONS="$HANDBRAKE_1280 $HANDBRAKE_VIDEO $HANDBRAKE_AUDIO $HANDBRAKE_X264_ATV1" ;;
	1920)
		case $audio in
			[0-9]) HANDBRAKE_AUDIO="$HANDBRAKE_AUDIO_AAC" ;;
			[0-9],[0-9]) HANDBRAKE_AUDIO="$HANDBRAKE_AUDIO_AC3" ;;
		esac
		HANDBRAKE_OPTIONS="$HANDBRAKE_1920 $HANDBRAKE_VIDEO $HANDBRAKE_AUDIO $HANDBRAKE_X264_ATV3" ;;
	*)
		echo 'Invalid encoding mode selected.'
		exit 1 ;;
esac

# the actual encode
HandBrakeCLI -i "$source" -o "$stem".m4v --crop "$crop" --audio $audio $HANDBRAKE_OPTIONS $options

# perform pulldown and other postprocessing
case "$pulldown" in
	'')
		# open Subler to enter metadata
		open -b org.galad.Subler "$stem".m4v
		;;
	25-24)
		mv "$stem".m4v "$stem"_.m4v
		# demux to H.264 elementary stream (MP4Box synthesizes otherwise missing SPS and PPS)
		MP4Box -raw 1 "$stem"_.m4v -out "$stem".h264
		# convert to 24fps
		h264_frame_rate "$stem".h264
		# audio pulldown to 24fps, Dolby Prologic II downmix, encode to AAC
		ffmpeg -i "$stem"_.m4v -f s16le -ac 6 - | sox -t raw -e signed-integer -b 16 -L -c 6 -r 46080 - -t raw -e signed-integer -b 16 -L -r 48000 - remix -m 1v1.0000,3v0.7071,5v-0.8660,6v-0.5000 2v1.0000,3v0.7071,5v0.5000,6v0.8660 | aac_encode "$stem".aac
		# audio pulldown to 24fps, reencode to AC3
		ffmpeg -i "$stem"_.m4v -f s16le -ac 6 - | sox -t raw -e signed-integer -b 16 -L -c 6 -r 46080 - -t raw -e signed-integer -b 16 -L -c 6 -r 48000 - | ffmpeg -f s16le -ac 6 -ar 48000 -i - -ab 448k -y "$stem".ac3 2> /dev/null
		# use Subler to mux raw H.264, AAC and AC3
		echo
		echo "Please multiplex \"$stem.h264\", \"$stem.aac\" and \"$stem.ac3\"."
		echo '• Set the H.264 stream to 24fps.'
		echo '• Name the AAC and AC3 streams "Stereo" and "Surround" and assign them both to alternate group 1, with the AAC track being the fallback for the AC3.'
		echo '• Disable the AC3 stream.'
		echo '• Save with 64-bit file offsets.'
		open -b org.galad.Subler
		;;
esac
