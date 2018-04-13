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
#include "stdlib.h"
#include "stdio.h"

static bool audible = TRUE;

// In ev3dev-jessie, the console font will revert to the system setting on exit
#undef RESTORE_SETFONT
#define ARM_BBR_TERMFONT "Lat15-Terminus12x6.psf.gz"
#define SYSTEM_TERMFONT "Lat15-TomThumb4x6.psf.gz"


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

bool term_clearscr(void)
{
	printf(TERM_CLRSCR);
	return TRUE;
}

bool term_hidecursor(void)
{
	printf(TERM_HIDECURSOR);
	return TRUE;
}

bool term_showcursor(void)
{
	printf(TERM_SHOWCURSOR);
	return TRUE;
}


bool term_set_curpos(int col, int row)
{
	char curpos_sequence[] = TERM_CURPOS_FMT;

	if ((col < TERM_COL_MIN) || (col > TERM_COL_MAX) || (row < TERM_ROW_MIN) || (row > TERM_ROW_MAX))
		return FALSE;

	// Fill in the Row
	curpos_sequence[ROW_FMT_POS]   = '0' + row / 10;
    curpos_sequence[ROW_FMT_POS+1] = '0' + row % 10;

	// Fill in the Col
    curpos_sequence[COL_FMT_POS]   = '0' + col / 10;
    curpos_sequence[COL_FMT_POS+1] = '0' + col % 10;

    	printf(curpos_sequence);

    	return TRUE;
}

bool term_disp_string(char *string)
{
	printf(string);
	fflush(stdout);
	return TRUE;
}

/* Public Routines */

void prog_init(void)
{
	/* Program Initialization Routine */
	term_hidecursor();
	system("setfont " ARM_BBR_TERMFONT);		// Use legible font for status messages
	alrt_hello(audible);
	term_clearscr();
}

void prog_clearscreen(void)
{
	term_clearscr();
}

void prog_shutdown(void)
{
	/* Program Shutdown Routine */
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
