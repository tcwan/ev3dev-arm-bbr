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

static bool audible = TRUE;

// In ev3dev-jessie, the console font will revert to the system setting on exit
#undef RESTORE_SETFONT
#define ARM_BBR_TERMFONT "Lat15-Terminus12x6.psf.gz"
#define SYSTEM_TERMFONT "Lat15-TomThumb4x6.psf.gz"


/* Internal Routines */
bool term_set_curpos(int col, int row)
{
	return TRUE;
}

bool term_disp_string(char *string)
{
	return TRUE;
}

/* Public Routines */

void prog_init(void)
{
	/* Program Initialization Routine */
	system("setfont " ARM_BBR_TERMFONT);		// Use legible font for status messages
	alrt_hello(audible);
}


void prog_shutdown(void)
{
	/* Program Shutdown Routine */
#ifdef RESTORE_SETFONT
	system("setfont " SYSTEM_TERMFONT);		// Use legible font for status messages
#endif
	alrt_goodbye(audible);

}

void prog_title(char *string)
{
	/* Display Title string on LCD Screen */
	prog_contentX(string, 0);
}

void prog_content1(char *string)
{
	/* Display Content string on LCD Screen on Row 2 */
	prog_contentX(string, 2);
}

void prog_content2(char *string)
{
	/* Display Content string on LCD Screen on Row 4 */
	prog_contentX(string, 4);
}

void prog_contentX(char *string, int row)
{
	/* Display Content string on LCD Screen on Row X */
	term_set_curpos(0, row);
	term_disp_string(string);
}
