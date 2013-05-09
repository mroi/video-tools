/* Modifies a given H.264 elementary stream inplace. It expects the very specific
 * stream layout output by MP4Box demuxing. Especially, it expects an SPS as the
 * very first NALU. It changes the VUI in this one SPS from 25 to 24fps. */

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sysexits.h>

#define CHECK(x) if (!(x)) { fprintf(stderr, "failed check in line %d\n", __LINE__); abort(); }


static uint8_t buffer[4096];
static struct {
	uint8_t *buffer;
	size_t bitpos;
} bits = {
	.buffer = buffer,
	.bitpos = 0
};

static unsigned get_bits(size_t count)
{
	unsigned result = 0;
	while (count) {
		uint8_t byte = bits.buffer[bits.bitpos >> 3];
		uint8_t bit = 1 & (byte >> (7 - (bits.bitpos & 7)));
		result = (result << 1) | bit;
		bits.bitpos++;
		count--;
		if ((bits.bitpos & 7) == 0) {
			/* new byte entered */
			size_t bytepos = bits.bitpos >> 3;
			CHECK(bytepos < sizeof(buffer) / sizeof(uint8_t));
			if (bytepos > 1 && buffer[bytepos-2] == 0 && buffer[bytepos-1] == 0 && buffer[bytepos] == 3)
				/* skip emulation prevention byte */
				bits.bitpos += 8;
		}
	}
	return result;
}

static void put_bits(size_t count, unsigned value)
{
	while (count) {
		uint8_t bit = 1 & (value >> (count - 1));
		bit <<= (7 - (bits.bitpos & 7));
		uint8_t byte = bits.buffer[bits.bitpos >> 3];
		byte &= ~(1 << (7 - (bits.bitpos & 7)));
		byte |= bit;
		bits.buffer[bits.bitpos >> 3] = byte;
		bits.bitpos++;
		count--;
		if ((bits.bitpos & 7) == 0) {
			/* new byte entered */
			size_t bytepos = bits.bitpos >> 3;
			CHECK(bytepos < sizeof(buffer) / sizeof(uint8_t));
			if (bytepos > 1 && buffer[bytepos-2] == 0 && buffer[bytepos-1] == 0 && buffer[bytepos] > 4) {
				CHECK(buffer[bytepos] == 3);
				/* skip emulation prevention byte */
				bits.bitpos += 8;
			}
		}
	}
}

static unsigned get_exp_golomb_bits()
{
	size_t leading_zeros = 0;
	while (get_bits(1) == 0)
		leading_zeros++;
	return (1 << leading_zeros) - 1 + get_bits(leading_zeros);
}


int main(int argc, const char **argv)
{
	FILE *file;
	size_t size;
	
	if (argc != 2) {
		fprintf(stderr, "Usage: h264_frame_rate <H.264 elementary file>\n");
		return EX_USAGE;
	}
	
	file = fopen(argv[1], "r+");
	if (!file) return EX_NOINPUT;
	
	size = fread(buffer, sizeof(uint8_t), sizeof(buffer) / sizeof(uint8_t), file);

	/* NALU start code prefix */
	CHECK(get_bits(8) == 0);
	CHECK(get_bits(8) == 0);
	CHECK(get_bits(8) == 0);
	CHECK(get_bits(8) == 1);
	
	/* NALU type SPS */
	(void)get_bits(3);
	CHECK(get_bits(5) == 7);
	
	/* sequence parameter set */
	(void)get_bits(8 + 3 * 1 + 5 + 8);
	(void)get_exp_golomb_bits();                       // seq_parameter_set_id
	(void)get_exp_golomb_bits();                       // log2_max_frame_num_minus4
	unsigned pic_order_cnt_type = get_exp_golomb_bits();
	if (pic_order_cnt_type == 0) {
		(void)get_exp_golomb_bits();                   // log2_max_pic_order_cnt_lsb_minus4
	} else if (pic_order_cnt_type == 1) {
		(void)get_bits(1);                             // delta_pic_order_always_zero_flag
		(void)get_exp_golomb_bits();                   // offset_for_non_ref_pic
		(void)get_exp_golomb_bits();                   // offset_for_top_to_bottom_field
		unsigned num_ref_frames_in_pic_order_cnt_cycle  = get_exp_golomb_bits();
		unsigned i;
		for (i = 0; i < num_ref_frames_in_pic_order_cnt_cycle; i++)
			(void)get_exp_golomb_bits();               // offset_for_ref_frame
	}
	(void)get_exp_golomb_bits();                       // num_ref_frames
	(void)get_bits(1);                                 // gaps_in_frame_num_value_allowed_flag
	CHECK(get_exp_golomb_bits() == (1280 / 16) - 1);   // pic_width_in_mbs_minus1
	CHECK(get_exp_golomb_bits() <= (720 / 16) - 1);    // pic_height_in_map_units_minus1
	unsigned frame_mbs_only_flag = get_bits(1);
	if (!frame_mbs_only_flag)
		(void)get_bits(1);                             // mb_adaptive_frame_field_flag
	(void)get_bits(1);                                 // direct_8x8_inference_flag
	unsigned frame_cropping_flag = get_bits(1);
	if (frame_cropping_flag) {
		(void)get_exp_golomb_bits();                   // frame_crop_left_offset
		(void)get_exp_golomb_bits();                   // frame_crop_right_offset
		(void)get_exp_golomb_bits();                   // frame_crop_top_offset
		(void)get_exp_golomb_bits();                   // frame_crop_bottom_offset
	}
	CHECK(get_bits(1) == 1);                               // vui_parameters_present_flag
	
	/* VUI parameters */
	unsigned aspect_ratio_info_present_flag = get_bits(1);
	if (aspect_ratio_info_present_flag) {
		unsigned aspect_ratio_idc = get_bits(8);
		if (aspect_ratio_idc == 255)
			(void)get_bits(2 * 16);                    // Extended_SAR
	}
	unsigned overscan_info_present_flag = get_bits(1);
	if (overscan_info_present_flag)
		(void)get_bits(1);                             // overscan_appropriate_flag
	unsigned video_signal_type_present_flag = get_bits(1);
	if (video_signal_type_present_flag) {
		(void)get_bits(3 + 1);
		unsigned colour_description_present_flag = get_bits(1);
		if (colour_description_present_flag)
			(void)get_bits(3 * 8);
	}
	unsigned chroma_loc_info_present_flag = get_bits(1);
	if (chroma_loc_info_present_flag) {
		(void)get_exp_golomb_bits();                   // chroma_sample_loc_type_top_field
		(void)get_exp_golomb_bits();                   // chroma_sample_loc_type_bottom_field
	}
	CHECK(get_bits(1) == 1);                           // timing_info_present_flag
	
	/* timing info */
	CHECK(get_bits(32) == 1);                          // num_units_in_tick
	size_t timescale_pos = bits.bitpos;
	CHECK(get_bits(32) == 50);                         // time_scale
	bits.bitpos = timescale_pos;
	put_bits(32, 48);
	
	/* Makes sure our change from 50 to 48 - which clears one bit - does not add 
         * a start code alias which would require 0x03 insertion. */
	CHECK(get_bits(16) != 0);
	
	if (fseek(file, 0, SEEK_SET) != 0)
		return EX_IOERR;
	if (fwrite(buffer, sizeof(uint8_t), size, file) != size)
		return EX_IOERR;
	
	return EX_OK;
}
