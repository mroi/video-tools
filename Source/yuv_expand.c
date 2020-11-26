/* custom headroom and footroom removal for raw YUV stream */

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>


int main(int argc, char **argv)
{
	if (argc < 5) return 0;
	
	size_t width = (size_t)atoi(argv[1]);
	size_t height = (size_t)atoi(argv[2]);
	uint_fast8_t downshift = (uint8_t)atoi(argv[3]);
	float scale = (float)atof(argv[4]);
	
	uint8_t *buffer = malloc(width * height);
	
	size_t frames = 0;
	
	while (!feof(stdin)) {
		/* Y */
		fread(buffer, 1, width * height, stdin);
		for (size_t i = 0; i < width * height; i++) {
			if (buffer[i] > downshift) {
				buffer[i] -= downshift;
				buffer[i] *= scale;
			} else
				buffer[i] = 0;
		}
		fwrite(buffer, 1, width * height, stdout);
		/* UV */
		fread(buffer, 1, (width * height) >> 1, stdin);
		fwrite(buffer, 1, (width * height) >> 1, stdout);
		frames++;
	}
	
	printf("%zd frames processed.\n", frames);
	
	return 0;
}
