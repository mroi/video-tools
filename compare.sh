#!/bin/bash

# you can put the tools next to the script
PATH="`perl -e 'use File::Basename; use Cwd "abs_path";print dirname(abs_path($ARGV[0]));' "$0"`:$PATH"

tmpdir="`mktemp -d -t mp4-compare`"
mkfifo "$tmpdir/track"

function fingerprint() {
	file --brief --mime-type "$1" | fgrep -q /mp4 || return
	AtomicParsley "$1" -T + | sed -n '/^Movie duration/,$p'
	for ((i=1;i;i++)) ; do
		MP4Box "$1" -info $i | fgrep -q 'No track' && break
		echo -n "track $i "
		MP4Box -quiet "$1" -raw $i -new -out "$tmpdir/track" &
		md5 < "$tmpdir/track"
	done
	AtomicParsley "$1" -e "$tmpdir/embed" > /dev/null
	md5 "$tmpdir/embed"*
	rm "$tmpdir/embed"*
	AtomicParsley "$1" -t | sort
}

function compare() {
	fp1="$tmpdir/`basename "$1"`-left"
	fp2="$tmpdir/`basename "$2"`-right"
	fingerprint "$1" > "$fp1"
	fingerprint "$2" > "$fp2"
	cmp -s "$fp1" "$fp2" || diff -u "$fp1" "$fp2"
}

if test -d "${@: -1}" ; then
	for arg ; do
		test "$arg" = "${@: -1}" && break
		compare "$arg" "${@: -1}/`basename "$arg"`"
	done
else
	compare "$1" "$2"
fi

rm -rf "$tmpdir"
