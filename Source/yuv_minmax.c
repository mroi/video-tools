/* determines the dynamic range of a raw YUV stream */

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>


int main(int argc, char **argv)
{
	if (argc < 3) return 0;
	
	size_t width = atoi(argv[1]);
	size_t height = atoi(argv[2]);
	
	uint8_t *buffer = malloc(width * height);
	
	size_t frames = 0;
	uint_fast8_t y_min = 0xff, y_max = 0;
	uint_fast8_t uv_min = 0xff, uv_max = 0;
	
	while (!feof(stdin)) {
		/* Y */
		fread(buffer, 1, width * height, stdin);
		for (size_t i = 0; i < width * height; i++) {
			if (buffer[i] < y_min) y_min = buffer[i];
			if (buffer[i] > y_max) y_max = buffer[i];
		}
		/* UV */
		fread(buffer, 1, (width * height) >> 1, stdin);
		for (size_t i = 0; i < (width * height) >> 1; i++) {
			if (buffer[i] < uv_min) uv_min = buffer[i];
			if (buffer[i] > uv_max) uv_max = buffer[i];
		}
		frames++;
	}
	
	printf("%zd frames analysed.\n", frames);
	printf("Y range: %d - %d\n", y_min, y_max);
	printf("UV range: %d - %d\n", uv_min, uv_max);
	
	return 0;
}
