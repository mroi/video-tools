TOOLS = AtomicParsley HandBrakeCLI MP4Box Subler.app

.PHONY: all

all: $(TOOLS)

%:
	@which $@ &> /dev/null || { \
		echo 'Please get $@. Recommended version \c' ; \
		case $@ in \
			(AtomicParsley) echo '0.9.6.' ;; \
			(HandBrakeCLI) echo '1.3.3.' ;; \
			(MP4Box) echo '0.8.0.' ;; \
			(Subler.app) echo '1.6.5.' ;; \
		esac ; \
		false ; \
	}
