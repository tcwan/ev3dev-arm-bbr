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
 * Common Startup/Shutdown Routines for ARM-BBR programs
 */

/**
 * Initialize ARM-BBR subsystems
 */
void prog_init(void);                /* Program Initialization Routine */

/**
 * Shut down ARM-BBR subsystems
 */
void prog_shutdown(void);            /* Program Shutdown Routine */

/**
 * Display Title string on LCD (Row 0)
 *    @param string: Null-terminated string
 */
void prog_title(char *string);       /* Display Title string on LCD Screen */

/**
 * Display Content string on LCD (Row 2)
 *    @param string: Null-terminated string
 */
void prog_content1(char *string);     /* Display Content string on LCD Screen */

/**
 * Display Content string on LCD (Row 4)
 *    @param string: Null-terminated string
 */
void prog_content2(char *string);     /* Display Content string on LCD Screen */

/**
 * Display Content string on LCD (Row row)
 *    @param string: Null-terminated string
 *    @param row int: Row Index
 */
void prog_contentX(char *string, int row);     /* Display Content string on LCD Screen */

/*@}*/
/*@}*/
