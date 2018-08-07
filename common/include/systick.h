/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   systick.h
 *  \brief  ARM-BBR system tick function prototypes
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once

#include "ev3dev-arm-ctypes.h"

/** @addtogroup common */
/*@{*/

#define TICKS_PER_SECOND  1000000
#define NANOSECONDS_PER_TICK 1000

/** @defgroup systick System Tick
 *
 * The System Tick library generates a monotically increasing value to act as system tick.
 * Each tick is 1 microsecond.
 *
 */
/*@{*/

/** Init System Tick
 *
 * @param None
 * @return None
 *
 * This function is called once at the beginning of the program to reset the tick count
 */
void tick_init(void);

/** Get System Tick
 *
 * @param None
 * @return System Tick
 *
 * Returns the tick count in microseconds
 */
U32 tick_systick(void);

/*@}*/
/*@}*/

