/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   systick.c
 *  \brief  ARM-BBR system tick routines
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#include "ev3dev-arm-ctypes.h"
#include "systick.h"
#include <time.h>

#define NANOSECONDS_PER_SECOND 1000000000L

static	struct timespec start_time = { 0, 0 };

void tick_init(void) {
	clock_gettime(CLOCK_REALTIME, &start_time);
}

U32 tick_systick(void) {
	struct timespec curr_time;
	long elapsed_time = 0;

	clock_gettime(CLOCK_REALTIME, &curr_time);

	elapsed_time = (curr_time.tv_nsec - start_time.tv_nsec)
				+ (curr_time.tv_sec - start_time.tv_sec) * NANOSECONDS_PER_SECOND;

	return (U32) (elapsed_time / NANOSECONDS_PER_TICK);
}
