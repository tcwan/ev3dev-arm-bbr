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

/* Internal Routines */
con_set_curpos(int col, int row)
{

}

con_disp_string(char *string)
{

}

/* Public Routines */

void prog_init(void)
{
	/* Program Initialization Routine */
}


void prog_shutdown(void)
{
	/* Program Shutdown Routine */
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
	con_set_curpos(0, row);
	con_disp_string(string);
}
