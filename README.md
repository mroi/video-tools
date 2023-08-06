Video Tools
===========

This is a loose compilation of a bunch of scripts and tools that I use to process movies and 
other media in Apple-style MPEG-4 format. It also contains some scripts for [Final Cut 
Pro](https://www.apple.com/final-cut-pro/) project maintenance.

**compare.sh**  
Compares MPEG-4 files with regard to the tracks they contain and their metadata.

**encode.sh**  
Takes anything [HandBrake](http://handbrake.fr/) understands and encodes to canonical 
Apple-style MPEG-4 with my custom [x264](http://www.videolan.org/developers/x264.html) 
options.

**fcpdump.swift**  
Normalizes XML exports from Final Cut Pro X to make them suitable for diff’ing.

**fcpcheck.swift**  
Processes XML exports from Final Cut Pro X to report some of my personal pet peeves in 
projects, like forgotten keywords.

**fcpcompress.fish**  
A collection of [Fish shell](https://fishshell.com) code snippets that are helpful when 
compressing media inside a Final Cut Pro X project for archiving.

In addition, a [Nix flake](https://nixos.wiki/wiki/Flakes) allows to build the following 
externally hosted tools:

[**ffmpeg**](https://ffmpeg.org)  
The Swiss army knife of audio and video tools.

___
Because I sometimes reuse code from GPL’ed projects, everything in here is licensed under 
the terms of the [GNU GPLv3](http://www.gnu.org/licenses/quick-guide-gplv3).
