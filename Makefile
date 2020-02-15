TOOLS = AtomicParsley HandBrakeCLI MP4Box Subler.app aac_encode

.PHONY: all clean

all: $(TOOLS)

%: Source/%.c
	$(CC) -O3 -Weverything -o $@ $< \
		$(if $(filter aac_encode,$@),-framework AudioToolbox -framework CoreFoundation)

%:
	@which $@ &> /dev/null || { \
		echo 'Please get $@. Recommended version \c' ; \
		case $@ in \
			(AtomicParsley) echo '0.9.6.' ;; \
			(HandBrakeCLI) echo '1.3.1.' ;; \
			(MP4Box) echo '0.7.1.' ;; \
			(Subler.app) echo '1.5.14.' ;; \
		esac ; \
		false ; \
	}

clean:
	rm -f $(foreach source,$(wildcard Source/*),$(basename $(notdir $(source))))
