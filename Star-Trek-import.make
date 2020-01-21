SEASONS ?= $(or $(SEASON),$(wildcard TNG_[0-9]) $(wildcard DS9_[0-9]))
TITLES ?= 2 3 4 5
FFMPEG ?= ffmpeg
HANDBRAKE ?= $(dir $(realpath $(MAKEFILE_LIST)))/HandBrakeCLI
X264 ?= nice $(dir $(realpath $(MAKEFILE_LIST)))/x264

atv_import = \
	echo '* import to TV' ; \
	open -R $@ ; \
	echo read ; read _ ; \
	xattr -c $@ ; \
	tv="$$HOME/Movies/TV/Media/TV Shows" ; \
	$(if $(filter TNG_%,$*),ep="$$tv/Star Trek_ The Next Generation",:) ; \
	$(if $(filter DS9_%,$*),ep="$$tv/Star Trek_ Deep Space Nine",:) ; \
	ep="$$(ls "$$ep/$$(echo $* | sed 's/..._/Season /') "*)" ; \
	target="$$(echo "/Volumes/Thunderbolt HD$$ep" | sed 's|/Media/|/Filmarchiv/|')" ; \
	mkdir -p "$$(dirname "$$target")" ; ln $@ "$$target" ; \
	rm "$$ep" ; ln -s "../../../../Filmarchiv/TV Shows/$${ep\#$$tv/}" "$$ep"

START = $(foreach season,$(SEASONS), \
		$(if $(filter TNG_%,$(season)),$(wildcard $(season)/*_HD.h264) $(season)/01_HD.h264) \
		$(if $(filter DS9_%,$(season)),$(wildcard $(season)/*.mkv) $(season)/01.mkv) \
	)

all: $(foreach episode,$(START),$(episode:_HD.h264=.m4v) $(episode:.mkv=.m4v))
dvd: $(filter %.mkv,$(START:_HD.h264=_SD.mkv))

.PRECIOUS: %_HD.h264 %_SD.m4v %_SD.mkv

bonus:
	@for title in $(TITLES) ; do \
		caffeinate $(HANDBRAKE) --format mkv --markers --modulus 2 --color-matrix pal --custom-anamorphic --pixel-aspect 16:15 --comb-detect --decomb=bob --rate 50 --encoder x264 --quality 23 --encoder-preset slow --encoder-profile high --encoder-level 4.1 --aencoder ca_aac --ab 128 --arate 48 --mixdown dpl2 --subtitle 3,1,2,4,5,6,7,8,9 -i /Volumes/EU_* --title $$title -o $(lastword $(SEASONS))/$$((101 + title - $(firstword $(TITLES)))).mkv ; \
	done

%_HD.h264:
	@for episode in /Volumes/Extern\ HD/TNG/$(@D)/* ; do \
		target=$(@D)/$$(echo "$${episode}" | cut -c33-34)_HD.h264 ; \
		test -f $$target && continue ; \
		$(FFMPEG) -i "$$episode" -vcodec copy $$target ; \
	done

%_SD.mkv:
	@echo 'Handbrake: import $@ from title $(firstword $(TITLES))'
	@echo '* insert the next DVD to import'
	@echo '* extract chapter titles'
	./Capitalization.pl | pbcopy
	@for title in $(TITLES) ; do \
		caffeinate $(HANDBRAKE) --format mkv --markers --modulus 2 --color-matrix pal --custom-anamorphic --pixel-aspect 16:15 --comb-detect --decomb --encoder x264 --quality 23 --encoder-preset ultrafast --encoder-profile high --encoder-level 4.1 --audio 2,2,1,1,3,4,5 --aencoder ca_aac,copy:ac3,ca_aac,copy:ac3,ca_aac,ca_aac,ca_aac --ab 128,auto,128,auto,128,128,128 --arate 48,auto,48,auto,48,48,48 --mixdown dpl2,auto,dpl2,auto,dpl2,dpl2,dpl2 --subtitle 3,1,2,4,5,6,7,8,9 -i /Volumes/EU_* --title $$title -o $(@D)/$$(printf %02d_SD.mkv $$(($(*F:0%=%) + title - $(firstword $(TITLES))))) ; \
	done
	diskutil eject /Volumes/EU_*

%.mkv:
	@echo 'Handbrake: import $@ from title $(firstword $(TITLES))'
	@echo '* insert the next DVD to import'
	@echo '* extract chapter titles'
	./Capitalization.pl | pbcopy
	@for title in $(TITLES) ; do \
		caffeinate $(HANDBRAKE) --format mkv --markers --modulus 2 --color-matrix pal --custom-anamorphic --pixel-aspect 16:15 --comb-detect --decomb --nlmeans=light --encoder x264 --quality 23 --encoder-preset slow --encoder-profile high --encoder-level 4.1 --audio 1,1,2,2,3,4,5 --aencoder ca_aac,copy:ac3,ca_aac,copy:ac3,ca_aac,ca_aac,ca_aac --ab 128,auto,128,auto,128,128,128 --arate 48,auto,48,auto,48,48,48 --mixdown dpl2,auto,dpl2,auto,dpl2,dpl2,dpl2 --subtitle 2,4,3,5,6,7,8,9,10 -i /Volumes/EU_* --title $$title -o $(@D)/$$(printf %02d.mkv $$(($(*F:0%=%) + title - $(firstword $(TITLES))))) ; \
	done
	diskutil eject /Volumes/EU_*

%_SD.m4v: %_SD.mkv
	@echo 'Subler: import $<'
	@echo '* disable metadata import and set AC3 to passthrough'
	@echo '* clear track titles for sound'
	@echo '* set surround fallback'
	@echo '* add metadata and chapter titles'
	@echo '* save as $@'
	@open -a Subler $<
	@open Metadaten.numbers
	read _
	@! ffmpeg -i $@ 2>&1 | fgrep -q 'Chapter 1' || { echo 'Chapter titles not set.' && false ; }

%_HD.m4v: %_HD.h264
	@echo 'Subler: import $<'
	@echo '* set to 25fps'
	@echo '* save as $@'
	@open -a Subler $<
	read _

%.h264: %_HD.h264 %_SD.m4v %_HD.m4v
	@echo 'Final Cut Pro:'
	@echo '* add $*_SD.m4v to empty time line'
	@echo '* overlay $*_HD.m4v with 50% opacity'
	@echo '* edit to match timing'
	@echo '* enter segment start and duration in frames'
	@open Star\ Trek.fcpbundle
	@open -R $*_SD.m4v
	cat > $*_EDL
	@i=0 ; while read start duration ; do \
		fifo=$$(printf $*_%02d $$i) ; \
		mkfifo $$fifo ; \
		$(FFMPEG) -v quiet -i $< -f rawvideo -vsync 0 -vf "select=gte(n\,$$start)" -frames:v $$duration -y $$fifo & \
		i=$$((i+1)) ; \
	done < $*_EDL
	@res=$$(ffmpeg -i $< 2>&1 | egrep -o '[0-9]+x[0-9]+') ; \
	cat $*_[0-9]* | caffeinate $(X264) --input-res $$res --fps 25 --range tv --colorprim bt709 --transfer bt709 --colormatrix bt709 --profile high --level 4.1 --preset medium --crf 23 -o $@ - ; \
	rm $*_EDL $*_[0-9]*

%.m4v: %.h264 %_SD.m4v
	@echo 'Subler: import $<'
	@echo '* set to 25fps'
	@echo '* import $*_SD.m4v, enable metadata import'
	@echo '* disable all video tracks'
	@echo '* set video language to English'
	@echo '* save as $@'
	@open -a Subler $<
	@open -R $*_SD.m4v
	read _
	@$(atv_import)

%.m4v: %.mkv
	@echo 'Subler: import $<'
	@echo '* disable metadata import and set AC3 to passthrough'
	@echo '* set video language to English'
	@echo '* clear track titles for sound'
	@echo '* set surround fallback'
	@echo '* add metadata and chapter titles'
	@echo '* save as $@'
	@open -a Subler $<
	read _
	@$(atv_import)
