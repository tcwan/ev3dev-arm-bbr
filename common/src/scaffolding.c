/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   scaffolding.c
 *  \brief  ARM-BBR scaffolding routines
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#include "ev3dev-arm-ctypes.h"
#include "alerts.h"
#include "scaffolding.h"
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

static bool audible = TRUE;

// In ev3dev-jessie, the console font will revert to the system setting on exit
#undef RESTORE_SETFONT
#undef DEBUG_TTYTYPE

#define ARM_BBR_TERMFONT "Lat15-Terminus12x6.psf.gz"
#define SYSTEM_TERMFONT "Lat15-TomThumb4x6.psf.gz"

#define FBCON_TTYNAME  "/dev/tty"
#define BUFSIZE 64


/* Internal Routines */
//
// Refer to man console_codes for information regarding escape sequences
//

#define TERM_CLRSCR "\x1B[2J"
#define TERM_SHOWCURSOR "\x1B[?25h"
#define TERM_HIDECURSOR "\x1B[?25l"

#define TERM_CURPOS_FMT "\x1B[00;00H"
#define ROW_FMT_POS 2
#define COL_FMT_POS 5

static bool is_FBConsole;

// 4-bit Binary LUT
static const char bit_rep[16][5] = {
    [ 0] = "0000", [ 1] = "0001", [ 2] = "0010", [ 3] = "0011",
    [ 4] = "0100", [ 5] = "0101", [ 6] = "0110", [ 7] = "0111",
    [ 8] = "1000", [ 9] = "1001", [10] = "1010", [11] = "1011",
    [12] = "1100", [13] = "1101", [14] = "1110", [15] = "1111",
};

typedef enum {
	NORMAL_INT,
	SIGNED_INT,
	UNSIGNED_INT,
	ALIGNED_INT,
	ALIGNED_SINT,
	ALIGNED_UINT,
	BIN8,
	HEX8,
	HEX32
} VALTYPE;

//
// TODO: Replace <stdio.h> routines with something more efficient
//
static inline bool term_clearscr(void)
{
	if (is_FBConsole) {
		fputs(TERM_CLRSCR, stdout);
		fflush(stdout);
	}
	return is_FBConsole;
}

static inline bool term_hidecursor(void)
{
	if (is_FBConsole) {
		fputs(TERM_HIDECURSOR, stdout);
		fflush(stdout);
	}
	return is_FBConsole;
}

static inline bool term_showcursor(void)
{
	if (is_FBConsole) {
		fputs(TERM_SHOWCURSOR, stdout);
		fflush(stdout);
	}
	return is_FBConsole;
}

static bool term_set_curpos(int col, int row)
{
	char curpos_sequence[] = TERM_CURPOS_FMT;

	if ((col < TERM_COL_MIN) || (col > TERM_COL_MAX) || (row < TERM_ROW_MIN) || (row > TERM_ROW_MAX))
		return FALSE;

	if (is_FBConsole) {
		// Fill in the Row
		curpos_sequence[ROW_FMT_POS]   = '0' + row / 10;
		curpos_sequence[ROW_FMT_POS+1] = '0' + row % 10;

		// Fill in the Col
		curpos_sequence[COL_FMT_POS]   = '0' + col / 10;
		curpos_sequence[COL_FMT_POS+1] = '0' + col % 10;

    		fputs(curpos_sequence, stdout);
    		fflush(stdout);
	}
    	return is_FBConsole;
}

static inline bool term_disp_string(char *string)
{
	fputs(string, stdout);
	if (!is_FBConsole)
		fputs("\n", stdout);
	fflush(stdout);
	return TRUE;
}

static void print_bin(U8 value) {
	printf("0b%s%s", bit_rep[(value & 0xF0) >> 4], bit_rep[value & 0x0F]);
}

static bool term_disp_value(U32 value, VALTYPE type, U32 width)
{
	/* It does not make sense to provide alignment for Binary and Hex outputs */
	switch(type) {

	case SIGNED_INT:
		printf("%+ld",(S32) value);
		break;

	case UNSIGNED_INT:
		printf("%lu",(U32) value);
		break;

	case ALIGNED_INT:
		printf("%*ld",(int) width, (S32) value);
		break;

	case ALIGNED_SINT:
		printf("%+*ld",(int) width, (S32) value);
		break;

	case ALIGNED_UINT:
		printf("%*lu",(int) width, (S32) value);
		break;

	case BIN8:
		print_bin((U8) value & 0xFF);
		break;

	case HEX8:
		printf("0x%02X",(U8) value & 0xFF);
		break;

	case HEX32:
		printf("0x%08lX",(U32) value);
		break;

	case NORMAL_INT:
	default:
		printf("%ld", (S32) value);
		break;
	}

	if (!is_FBConsole)
		fputs("\n",stdout);
	fflush(stdout);
	return TRUE;
}


/* Public Routines */

void prog_init(void)
{
	/* Program Initialization Routine */

	// Check if we're running on Frameb Buffer Console, or else in Debugger w/o ncurses support.
	char ttynamestr[BUFSIZE];
	if (0 == ttyname_r(STDOUT_FILENO, ttynamestr, sizeof(ttynamestr))) {
#ifdef DEBUG_TTYTYPE
		printf("ttyname = %s", ttynamestr);
		fflush(stdout);
		sleep(5);
#endif
		is_FBConsole = (NULL != strstr(ttynamestr, FBCON_TTYNAME));
	}

	term_hidecursor();
	term_clearscr();
	system("setfont " ARM_BBR_TERMFONT);		// Use legible font for status messages
	alrt_hello(audible);
}

void prog_exit(void)
{
	/* Program Exit Routine */
#ifdef RESTORE_SETFONT
	system("setfont " SYSTEM_TERMFONT);		// Use legible font for status messages
#endif
	alrt_goodbye(audible);
	term_showcursor();

}

void prog_title(char *string)
{
	//printf("Debug: prog_title()\n");
	/* Display Title string on LCD Screen */
	prog_contentX(string, 1);
}

void prog_content1(char *string)
{
	//printf("Debug: prog_content1()\n");
	/* Display Content string on LCD Screen on Row 3 */
	prog_contentX(string, 3);
}

void prog_content2(char *string)
{
	//printf("Debug: prog_content2()\n");
	/* Display Content string on LCD Screen on Row 5 */
	prog_contentX(string, 5);
}

void prog_contentX(char *string, int row)
{
	/* Display Content string on LCD Screen on Row X */
	term_set_curpos(1, row);
	term_disp_string(string);
}

void prog_clearscreen(void)
{
	term_clearscr();
}

bool prog_set_cursorpos(int col, int row) {
	return term_set_curpos(col, row);
}

void prog_display_string(char *string)
{
	//printf("Debug: prog_display_string()\n");
	/* Display string on LCD Screen at current cursor position */
	term_disp_string(string);
}

void prog_display_integer(S32 value)
{
	//printf("Debug: prog_display_integer()\n");
	/* Display signed integer value at current cursor position */
	term_disp_value(value, NORMAL_INT, 0);
}

void prog_display_integer_aligned(S32 value, U32 width)
{
	//printf("Debug: prog_display_integer()\n");
	/* Display signed integer value right aligned at current cursor position  */
	term_disp_value(value, ALIGNED_INT, width);
}


void prog_display_signed_int(S32 value)
{
	//printf("Debug: prog_display_signed_int()\n");
	/* Display signed integer value at current cursor position with sign (+ or -) */
	term_disp_value(value, SIGNED_INT, 0);
}

void prog_display_signed_int_aligned(S32 value, U32 width)
{
	//printf("Debug: prog_display_signed_int()\n");
	/* Display signed integer value at current cursor position with sign (+ or -) */
	term_disp_value(value, ALIGNED_SINT, width);
}

void prog_display_unsigned_int(U32 value)
{
	//printf("Debug: prog_display_unsigned_int()\n");
	/* Display unsigned integer value at current cursor position */
	term_disp_value(value, UNSIGNED_INT, 0);
}

void prog_display_unsigned_int_aligned(U32 value, U32 width)
{
	//printf("Debug: prog_display_unsigned_int()\n");
	/* Display unsigned integer value at current cursor position */
	term_disp_value(value, ALIGNED_UINT, width);
}

void prog_display_bin8(U8 binvalue)
{
	//printf("Debug: prog_display_bin8()\n");
	/* Display 8-bit binary value at current cursor position */
	term_disp_value((U32) binvalue, BIN8, 0);
}

void prog_display_hex8(U8 hexvalue)
{
	//printf("Debug: prog_display_hex8()\n");
	/* Display 8-bit hexadecimal value at current cursor position */
	term_disp_value((U32) hexvalue, HEX8, 0);
}


void prog_display_hex32(U32 hexvalue)
{
	//printf("Debug: prog_display_hex32()\n");
	/* Display 32-bit hexadecimal value at current cursor position */
	term_disp_value(hexvalue, HEX32, 0);
}

