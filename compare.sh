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

tmpdir=$(mktemp -d -t mp4-compare)
mkfifo "$tmpdir/track.out"

fingerprint() {
	file --brief --mime-type "$1" | grep -Eq '/(mp4|x-m4[av])$' || return
	AtomicParsley "$1" -T + | sed -n '/^Movie duration/,$p'
	i=1
	while true ; do
		MP4Box "$1" -info $i 2>&1 | grep -Fq 'No track' && break
		printf "track %d " $i
		MP4Box -quiet "$1" -raw "$i:output=$tmpdir/track.out" &
		md5 < "$tmpdir/track.out"
		i=$((i+1))
	done
	AtomicParsley "$1" -e "$tmpdir/embed" > /dev/null
	md5 "$tmpdir/embed"*
	rm "$tmpdir/embed"*
	AtomicParsley "$1" -t | sort
}

compare() {
	fp1=$tmpdir/$(basename "$1")-left
	fp2=$tmpdir/$(basename "$2")-right
	fingerprint "$1" > "$fp1"
	fingerprint "$2" > "$fp2"
	diff -sud "$fp1" "$fp2"
}

for last ; do true ; done
if test -d "$last" ; then
	for arg ; do
		test "$arg" = "$last" && break
		compare "$arg" "$last/$(basename "$arg")"
	done
else
	compare "$1" "$2"
fi

rm -rf "$tmpdir"
