#!/bin/sh

# you can put the tools next to the script
# shellcheck disable=SC2164
self=$(
	test "$(dirname "$0")" = . && cd "$(dirname "$(command -v "$0")")"
	test -d "$(dirname "$0")" && cd "$(dirname "$0")"
	test -L "$0" && cd "$(dirname "$(readlink "$0")")"
	pwd
)
PATH=$self:$PATH

HANDBRAKE_VIDEO='--format mp4 --modulus 2 --encoder x264 --quality 23'
HANDBRAKE_AUDIO='--aencoder ca_aac --ab 128 --arate 48 --mixdown dpl2'

HANDBRAKE_ANY='--custom-anamorphic --keep-display-aspect'
HANDBRAKE_320='--width 320 --hqdn3d=strong'
HANDBRAKE_640='--width 640'
HANDBRAKE_960='--width 960'
HANDBRAKE_1280='--width 1280'
HANDBRAKE_1920='--width 1920'

HANDBRAKE_X264_IPOD='--encoder-preset slow --encoder-profile baseline --encoder-level 3.0'
HANDBRAKE_X264_ATV1='--encoder-preset slow --encoder-profile main --encoder-level 3.1 --encopts cabac=0:ref=2:bframes=8:b-pyramid=none:weightb=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500'
HANDBRAKE_X264_ATV4='--encoder-preset slow --encoder-profile high --encoder-level 4.1'

# defaults
audio=true
mode='ANY'
options=''
source=''
stem=''

# parse command  line
for command ; do
	case "$command" in
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
		--audio)
			audio=false
			options="$options --audio" ;;
		*)
			if test -e "$command" ; then
				source="$command"
			else
				options="$options $command"
			fi
			;;
	esac
done

if ! test "$source" ; then
	echo "Usage: $(basename "$0") [320|640|960|1280|1920] <video> [options]"
	echo
	echo '320|640|960|1280|1920  the desired image width and encoding mode'
	echo 'video                  the source video file'
	echo 'options                other options to pass to HandBrake'
	exit 1
fi

stem=${source%.*}
stem=${stem##*/}

target="$stem".m4v
number=1
while test -e "$target" ; do
	target="$stem $number".m4v
	number=$((number + 1))
done

# set encoding options according to the mode
case "$mode" in
	320)
		HANDBRAKE_OPTIONS="$HANDBRAKE_VIDEO $HANDBRAKE_320 $HANDBRAKE_X264_IPOD" ;;
	640)
		HANDBRAKE_OPTIONS="$HANDBRAKE_VIDEO $HANDBRAKE_640 $HANDBRAKE_X264_IPOD" ;;
	960)
		HANDBRAKE_OPTIONS="$HANDBRAKE_VIDEO $HANDBRAKE_960 $HANDBRAKE_X264_ATV1" ;;
	1280)
		HANDBRAKE_OPTIONS="$HANDBRAKE_VIDEO $HANDBRAKE_1280 $HANDBRAKE_X264_ATV1" ;;
	1920)
		HANDBRAKE_OPTIONS="$HANDBRAKE_VIDEO $HANDBRAKE_1920 $HANDBRAKE_X264_ATV4" ;;
	ANY)
		HANDBRAKE_OPTIONS="$HANDBRAKE_VIDEO $HANDBRAKE_ANY $HANDBRAKE_X264_ATV4" ;;
esac

if $audio ; then
	HANDBRAKE_OPTIONS="$HANDBRAKE_OPTIONS $HANDBRAKE_AUDIO"
fi

# the actual encode
unset PS4
set -x
# shellcheck disable=SC2086
HandBrakeCLI -i "$source" -o "$target" $HANDBRAKE_OPTIONS $options
