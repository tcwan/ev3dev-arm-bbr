/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   b33.h
 *  \brief  Define common constants for b33 subprojects
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once


#ifdef __ASSEMBLY__

#define L_MOTOR_PORT      OUTPUT_B
#define L_MOTOR_EXT_PORT  EXT_PORT__NONE_
#define R_MOTOR_PORT      OUTPUT_C
#define R_MOTOR_EXT_PORT  EXT_PORT__NONE_

#define TACHO_MOTOR_TYPE    LEGO_EV3_L_MOTOR        // Use LEGO_EV3_M_MOTOR for Medium Servo Motor
#define TACHO_MAX_SPEED     200                     // Be careful not to set too large a number
#define TACHO_RAMPTIME_MS   100                     // 100 ms to ramp up/down to speed
#define TACHO_STOP_MODE     TACHO_BRAKE             // TACHO_COAST, TACHO_BRAKE, TACHO_HOLD
#define TACHO_RUN_MODE      TACHO_RUN_FOREVER       // TACHO_RUN_TO_REL_POS, TACHO_RUN_FOREVER

#endif
