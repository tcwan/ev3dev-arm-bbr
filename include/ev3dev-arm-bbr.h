/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   ev3dev-arm-bbr.h
 *  \brief  Top level ARM-BBR Header File for all library function prototypes to be included in ARM-BBR programs
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

//
// This file is manually created from the common/include C headers
//
#pragma once

#ifdef __ASSEMBLY__

#define __ARM_ARCH_V5T__					// To enable ARMv5T Interwork macros

#include "ev3dev-arm-defines.h"

/* C Library usleep constants */
	.equiv  MS_TO_US_MULTIPLIER, 1000
	.equiv	SLEEP_DURATION_10MS,   10 * MS_TO_US_MULTIPLIER
	.equiv	SLEEP_DURATION_20MS,   20 * MS_TO_US_MULTIPLIER
	.equiv	SLEEP_DURATION_50MS,   50 * MS_TO_US_MULTIPLIER
	.equiv	SLEEP_DURATION_100MS, 100 * MS_TO_US_MULTIPLIER
	.equiv	SLEEP_DURATION_200MS, 200 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_500MS, 500 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_1SEC, 1000 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_2SEC, 2000 * MS_TO_US_MULTIPLIER

	.extern usleep        /* C Library usleep() */


/* common/include/alerts.h */
	.extern alrt_hello
	.extern alrt_goodbye

/* common/include/scaffolding.h */
	.extern	prog_init
	.extern	prog_exit
	.extern prog_title
	.extern prog_content1
	.extern prog_content2
	.extern prog_contentX
	.extern prog_clearscreen
	.extern prog_set_cursorpos
	.extern prog_display_string
	.extern prog_display_integer
	.extern prog_display_integer_aligned
	.extern prog_display_signed_int
	.extern prog_display_signed_int_aligned
	.extern prog_display_unsigned_int
	.extern prog_display_unsigned_int_aligned
	.extern prog_display_bin8
	.extern prog_display_hex8
	.extern prog_display_hex32

	/* common/include/devices.h */
	.extern dvcs_search_dc_type_for_port
	.extern dvcs_search_sensor_type_for_port
	.extern dvcs_search_servo_type_for_port
	.extern dvcs_search_tacho_type_for_port

#endif
