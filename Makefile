ACTIVE_TOOLS = AtomicParsley HandBrakeCLI MP4Box SimpleMovieX.app Subler.app \
	aac_encode ffmpeg h264_frame_rate sox

.PHONY: all clean

all: $(ACTIVE_TOOLS)

%: Source/%.c
	$(CC) -O3 -Weverything -o $@ $< \
		$(if $(filter aac_encode,$@),-framework AudioToolbox -framework CoreFoundation)

%:
	@which $@ &> /dev/null || { \
		echo 'Please get $@. Tested with version \c' ; \
		case $@ in \
			(AtomicParsley) echo '0.9.4.' ;; \
			(HandBrakeCLI) echo '0.9.9.' ;; \
			(MP4Box) echo '0.5.0-rev4065.' ;; \
			(SimpleMovieX.app) echo '3.12.' ;; \
			(Subler.app) echo '0.19.' ;; \
			(ffmpeg) echo 'from current Git.' ;; \
			(sox) echo '14.3.0.' ;; \
		esac ; \
		false ; \
	}

clean:
	rm -f $(foreach source,$(wildcard Source/*),$(basename $(notdir $(source))))
