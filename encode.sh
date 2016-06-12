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

HANDBRAKE_X264_IPOD='--x264-preset slow --h264-profile baseline --h264-level 3.0'
HANDBRAKE_X264_ATV1='--x264-preset slow --h264-profile main     --h264-level 3.1 --encopts cabac=0:ref=2:bframes=8:b-pyramid=none:weightb=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500'
HANDBRAKE_X264_ATV3='--x264-preset slow --h264-profile high     --h264-level 4.0'

# defaults
audio=1
crop=''
mode=''
options=''
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
		*)
			source="$command" ;;
	esac
done

if ! test "$source" -a "$mode" ; then
	echo "Usage: $(basename "$0") [cropping] [audio channel(s)] [options] 320|640|960|1280|1920 <video>"
	echo
	echo '[cropping]             is of the form <top>:<bottom>:<left>:<right>'
	echo '[audio channel(s)]     is <num> or <num>,<num>; use the latter to add AC3'
	echo '[options]              other options to pass to HandBrake'
	echo '320|640|960|1280|1920  the desired image width; height depends on cropping'
	echo '<video>                the source video file'
	exit 1
fi

stem="${source%.*}"
test "$source" = "${stem}.eyetv" && source="`echo "$source"/*.mpg`"
stem="${stem##*/}"

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
