Video Tools
===========

This is a compilation of a bunch of scripts and small helper tools that I use to process and 
manage movies and other media in iTunes style MPEG-4 format. Among them are:

**aac_encode**  
Pipe in a 48kHz stereo s16le PCM stream. Uses QuickTime to convert to AAC.

**compare.sh**  
Compares MPEG-4 files with regard to the tracks they contain and their metadata.

**encode.sh**  
The main thing. Takes anything [HandBrake](http://handbrake.fr/) understands and encodes to
canonical iTunes style MPEG-4 with my custom [x264](http://www.videolan.org/developers/x264.html)
options.

**fixfcpxml.pl**  
Process XML exports from [Final Cut Pro X](https://www.apple.com/final-cut-pro/), reporting 
and sanitizing some of my personal pet peeves in projects, like forgotten keywords.

The scripts need a couple of tools along their way. You can place them right here into the 
project directory, because this will be in `$PATH`. The Makefile will help you collect 
everything needed or recommended.

Because I sometimes reuse code from GPL’ed projects, everything in here is licensed under 
the terms of the [GNU GPLv3](http://www.gnu.org/licenses/quick-guide-gplv3).
