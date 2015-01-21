ACTIVE_TOOLS = AtomicParsley HandBrakeCLI MP4Box Subler.app aac_encode ffmpeg h264_frame_rate sox

.PHONY: all clean

all: $(ACTIVE_TOOLS)

%: Source/%.c
	$(CC) -O3 -Weverything -o $@ $< \
		$(if $(filter aac_encode,$@),-framework AudioToolbox -framework CoreFoundation)

%:
	@which $@ &> /dev/null || { \
		echo 'Please get $@. Recommended version \c' ; \
		case $@ in \
			(AtomicParsley) echo '0.9.6.' ;; \
			(HandBrakeCLI) echo '0.10.0.' ;; \
			(MP4Box) echo '0.5.0-rev4065.' ;; \
			(Subler.app) echo '0.30.' ;; \
			(ffmpeg) echo 'from current Git.' ;; \
			(sox) echo '14.4.1.' ;; \
		esac ; \
		false ; \
	}

clean:
	rm -f $(foreach source,$(wildcard Source/*),$(basename $(notdir $(source))))
