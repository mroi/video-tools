SRC = $(wildcard *.c)
TGT = $(SRC:.c=)

.PHONY: all clean

all: $(TGT)

%: %.c
	$(CC) -O3 -Weverything -Wno-poison-system-directories -o $@ $< \
		$(if $(filter aac_encode,$@),-framework AudioToolbox -framework CoreFoundation)

clean:
	rm -f $(TGT)
