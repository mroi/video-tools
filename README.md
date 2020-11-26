Video Tools
===========

This is a loose compilation of a bunch of scripts and small helper tools and also the home 
for some downloaded tools that I use to process movies and other media in Apple-style MPEG-4 
format. It also contains some scripts for [Final Cut 
Pro](https://www.apple.com/final-cut-pro/) project maintenance.

**compare.sh**  
Compares MPEG-4 files with regard to the tracks they contain and their metadata.

**encode.sh**  
Takes anything [HandBrake](http://handbrake.fr/) understands and encodes to canonical 
Apple-style MPEG-4 with my custom [x264](http://www.videolan.org/developers/x264.html) 
options.

**fcpdump.swift**  
Normalizes XML exports from Final Cut Pro X to make them suitable for diff’ing.

**fcpfix.pl**  
Process XML exports from Final Cut Pro X, reporting and sanitizing some of my personal pet 
peeves in projects, like forgotten keywords.

You can place downloaded tools right here into the project directory, because this will be 
in `$PATH`. The Makefile will help you collect everything needed or recommended.

___
Because I sometimes reuse code from GPL’ed projects, everything in here is licensed under 
the terms of the [GNU GPLv3](http://www.gnu.org/licenses/quick-guide-gplv3).
