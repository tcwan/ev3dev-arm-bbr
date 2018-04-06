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

static bool audible = TRUE;


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
	alrt_hello(audible);
}


void prog_shutdown(void)
{
	/* Program Shutdown Routine */
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
