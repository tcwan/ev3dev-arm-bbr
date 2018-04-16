/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   alerts.h
 *  \brief  ARM-BBR alerts function prototypes
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once

#include "ev3dev-arm-ctypes.h"

/** @addtogroup common */
/*@{*/

/** @defgroup alerts Alert Sounds
 *
 * The Alerts library generate audio tones that can be used to indicate
 * system startup and shutdown.
 */
/*@{*/

/** Hello (startup) tone sequence
 *
 * @param audible: True for alert sequence to be generated
 * @return None
 *
 * The boolean parameter can be used to enable/disable alert
 * tone generation in the calling program
 */
void alrt_hello(bool audible);

/** Goodbye (shutdown) tone sequence
 *
 * @param audible: True for alert sequence to be generated
 * @return None
 * The boolean parameter can be used to enable/disable alert
 * tone generation in the calling program
 */
void alrt_goodbye(bool audible);

/** Generate tone
 *
 * @param frequency: Tone frequency in Hz
 * @param duration: Duration in ms
 * @return None
 * The tone with specified frequency and duration will be generated
 */
void alrt_tone(U32 frequency, U32 duration);

/*@}*/
/*@}*/

