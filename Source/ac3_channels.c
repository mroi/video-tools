/* This is not needed any more.
 * I thought I need to fixup some information about channel layout in the AC3
 * atom to enable passthrough in iTunes. This was wrong. Passthrough works in
 * both iTunes and QuickTime without that. */

#include <inttypes.h>
#include <stdio.h>
#include <assert.h>
#include <sysexits.h>

#ifdef __LITTLE_ENDIAN__
#define ATOM(a, b, c, d) (a << 24 | b << 16 | c << 8 | d << 0)
#define SCAN(buf) (buf[0] << 24 | buf[1] << 16 | buf[2] << 8 | buf[3] << 0)
#else
#error Big endian version not tested.
#endif


static int fixup_dac3_atom(FILE *file)
{
	printf("fixing dac3 atom\n");
	uint8_t byte;
	if (fread(&byte, sizeof(byte), 1, file) != 1) return EX_IOERR;
	assert(byte == 16);  // bsid (bits 1-5, counting from LSB) is 8
	if (fseek(file, -sizeof(byte), SEEK_CUR) != 0) return EX_IOERR;
	byte = 12;  // bsid must be 6 for passthrough to work
	if (fwrite(&byte, sizeof(byte), 1, file) != 1) return EX_IOERR;
	/* skip the rest of the dac3 atom */
	if (fseek(file, 3 - sizeof(byte), SEEK_CUR) != 0) return EX_IOERR;
	return EX_OK;
}

static int traverse_atom_tree(FILE *file, const uint32_t *path, uint32_t limit)
{
	uint32_t size;
	uint32_t type;
	
	while (limit && !feof(file)) {
		unsigned char buffer[4];
		
		if (fread(buffer, sizeof(size), 1, file) != 1)
			return EX_IOERR;
		size = SCAN(buffer);
		if (fread(buffer, sizeof(type), 1, file) != 1)
			return EX_IOERR;
		type = SCAN(buffer);
		
		{
			union {
				uint32_t in;
				char out[4];
			} convert1, convert2;
			convert1.in = type;
			convert2.in = path[0];
			printf("current %c%c%c%c, searching %c%c%c%c\n",
				   convert1.out[3], convert1.out[2], convert1.out[1], convert1.out[0],
				   convert2.out[3], convert2.out[2], convert2.out[1], convert2.out[0]);
		}
		if (type == path[0]) {
			printf("atom found, going one level in\n");
			unsigned extra_data = 0;  // some atoms have properties before sub-atoms
			switch (type) {
			case ATOM('s', 't', 's', 'd'):
				extra_data = 8;
				break;
			case ATOM('a', 'c', '-', '3'):
				extra_data = 28;
				break;
			}
			if (extra_data) {
				if (fseek(file, extra_data, SEEK_CUR) != 0)
					return EX_IOERR;
				size -= extra_data;
				limit -= extra_data;
			}
			if (path[1])
				traverse_atom_tree(file, path + 1, size - 2 * sizeof(uint32_t));
			else
				fixup_dac3_atom(file);
		} else {
			printf("skipping atom of size %d\n", size);
			if (fseek(file, size - 2 * sizeof(uint32_t), SEEK_CUR) != 0)
				return EX_IOERR;
		}
		assert(!(size > limit));
		limit -= size;
	}
	printf("atom exhausted, going one level up\n");
	
	return EX_OK;
}


int main(int argc, char **argv)
{
	FILE *file;
	
	if (argc != 2) {
		fprintf(stderr, "Usage: ac3_channels <MPEG-4 file>\n");
		return EX_USAGE;
	}
	
	file = fopen(argv[1], "r+");
	if (!file) return EX_NOINPUT;
	
	const uint32_t atom_path[] = {
		ATOM('m', 'o', 'o', 'v'),
		ATOM('t', 'r', 'a', 'k'),
		ATOM('m', 'd', 'i', 'a'),
		ATOM('m', 'i', 'n', 'f'),
		ATOM('s', 't', 'b', 'l'),
		ATOM('s', 't', 's', 'd'),
		ATOM('a', 'c', '-', '3'),
		ATOM('d', 'a', 'c', '3'),
		0
	};
	
	int result = traverse_atom_tree(file, atom_path, ~(uint32_t)0);
	if (result != 0) return result;
	
	return EX_OK;
}
