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

//
// Generic Output routines
//
/**
 * Set the cursor on the LCD to new cursor position
 * Note: This only works on the LCD screen.
 * It does not work in the Debugger output window.
 *    @param col: integer value
 *    @param row: integer value
 */
void prog_set_cursorpos(int col, int row);

/**
 * Display string on LCD at current cursor position
 *    @param string: Null-terminated string
 */
void prog_display_string(char *string);

/**
 * Display signed integer on LCD at current cursor position
 * The negative sign is displayed if it is negative,
 * otherwise no signed is displayed.
 *    @param value: signed long value
 */
void prog_display_integer(S32 value);

/**
 * Display signed integer on LCD at current cursor position
 * The sign is always displayed, regardless of the value
 * being positive or negative.
 *    @param value: signed long value
 */
void prog_display_signed_int(S32 value);

/**
 * Display unsigned integer on LCD at current cursor position
 *    @param value: unsigned long value
 */
void prog_display_unsigned_int(U32 value);

/**
 * Display 8-bit binary on LCD at current cursor position
 *    @param value: 8-bit binary value
 */
void prog_display_bin8(U8 binvalue);

/**
 * Display 32-bit hexadecimal on LCD at current cursor position
 *    @param value: 32-bit hexadecimal value
 */
void prog_display_hex32(U32 hexvalue);

/*@}*/
/*@}*/
