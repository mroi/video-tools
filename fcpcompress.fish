set --global target .
set --global profile main422-10
set --global video hevc
set --global audio aac
set --global data copy
set --global pcm pcm_s16le

function hevc --description 'shell with HEVC-enabled ffmpeg'
	nix shell --impure --expr '(import <nixpkgs> {}).ffmpeg.override { withX265 = true; }'
end

function mov --description 'compress MOV files'
	if test (count $argv) -gt 1
		iterate mov $argv
	else
		ffmpeg -loglevel error -stats -i $argv[1] \
			(switch $video
				case hevc; echo "-codec:v hevc -profile:v $profile -preset:v faster -tag:v hvc1 -x265-params log-level=-1"
				case none;
				case '*'; echo "-codec:v $video"
			end | string split ' ') \
			(switch $audio
				case none;
				case '*'; echo "-codec:a $audio"
			end | string split ' ') \
			(switch $data
				case none;
				case '*'; echo "-codec:d $data"
			end | string split ' ') \
			-fps_mode passthrough -map 0 -movflags use_metadata_tags -map_metadata 0 \
			out.mov
	end
end

function wav --description 'compress WAV files'
	if test (count $argv) -gt 1
		iterate wav $argv
	else
		ffmpeg -loglevel error -stats -i $argv[1] \
			-codec:a $pcm -map_metadata 0 \
			out.wav
		and ./bwfmetaedit --continue-errors --out-core=meta $argv[1]
		sed -i_ 's|^"[^"]*"|"out.wav"|;s/W=24/W=16/' meta
		and ./bwfmetaedit --in-core=meta
	end
end

function sqlite --description 'run VACUUM on sqlite files'
	if test (count $argv) -gt 1
		iterate sqlite $argv
	else
		cp -p $argv[1] out.sqlite
		and sqlite3 out.sqlite VACUUM\;
	end
end

function iterate --description 'iterate over multiple files to compress'
	caffeinate &
	set --function type $argv[1]
	set --erase argv[1]
	set --function index 0
	for file in $argv
		set index (math $index + 1)
		echo "[$index/"(count $argv)']' $file
		$type $file
		and touch -r $file out.$type
		and mv out.$type $target/$file
	end
	kill (jobs --pid)
end
