#!/bin/bash

# you can put the tools next to the script
PATH="`perl -e 'use File::Basename; use Cwd "abs_path";print dirname(abs_path($ARGV[0]));' "$0"`:$PATH"

ffmpeg -i "$1" -vn -f s16le -ac 2 - | sox -t raw -e signed-integer -b 16 -L -c 2 -r 48000 - "$2" remix -m 1v0.4088,2v0.0599 1v0.0599,2v0.4088 1v0.3314,2v0.3314 1v0,2v0 1v-0.3241,2v0.1526 1v-0.1526,2v0.3241
