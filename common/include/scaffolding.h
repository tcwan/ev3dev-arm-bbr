/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   scaffolding.h
 *  \brief  ARM-BBR scaffolding function prototypes
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once

#include "ev3dev-arm-ctypes.h"

/** @addtogroup common */
/*@{*/

/**
 * Text Terminal Screen Dimensions
 */
#define TERM_COL_MIN  1
#define TERM_COL_MAX 29
#define TERM_ROW_MIN  1
#define TERM_ROW_MAX 10

/**
 * Common Startup/Shutdown Routines for ARM-BBR programs
 */

/**
 * Initialize ARM-BBR subsystems
 * Clears LCD screen and generate startup tone
 */
void prog_init(void);                /* Program Initialization Routine */

/**
 * Clear the LCD Text Display. Cursor will be placed at (1,1) (Top Left)
 */
void prog_clearscreen(void);                /* LCD Text Screen Init Routine */

/**
 * Shut down ARM-BBR subsystems
 * Generate shutdown tone
 */
void prog_shutdown(void);            /* Program Shutdown Routine */

/**
 * Display Title string on LCD (Row 1)
 *    @param string: Null-terminated string
 */
void prog_title(char *string);       /* Display Title string on LCD Screen */

/**
 * Display Content string on LCD (Row 3)
 *    @param string: Null-terminated string
 */
void prog_content1(char *string);     /* Display Content string on LCD Screen */

/**
 * Display Content string on LCD (Row 5)
 *    @param string: Null-terminated string
 */
void prog_content2(char *string);     /* Display Content string on LCD Screen */

/**
 * Display Content string on LCD (Row row)
 *    @param string: Null-terminated string
 *    @param row int: Row Index [1..MAX_ROW]
 */
void prog_contentX(char *string, int row);     /* Display Content string on LCD Screen */

/*@}*/
/*@}*/
