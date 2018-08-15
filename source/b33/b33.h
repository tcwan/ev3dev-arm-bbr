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

#include "ev3dev-arm-bbr.h"

#define ROBOT_STATE_ROW		7						// Robot State Display Row on output screen
#define ROBOT_DEBUG_ROW		8						// Robot Debug Display Row on output screen
#define DEBUG_INT_WIDTH     6						// Alignment width for integer value

#define EVENTLOOP_TICKCOUNT 100 * TICKS_PER_MSEC	// 100 ms per event loop

#define L_MOTOR_PORT      OUTPUT_B
#define L_MOTOR_EXT_PORT  EXT_PORT__NONE_
#define R_MOTOR_PORT      OUTPUT_C
#define R_MOTOR_EXT_PORT  EXT_PORT__NONE_

#define TACHO_MOTOR_TYPE    LEGO_EV3_L_MOTOR        // Use LEGO_EV3_M_MOTOR for Medium Servo Motor
#define TACHO_MAX_SPEED     200                     // Be careful not to set too large a number
#define TACHO_RAMPTIME_MS   100                     // 100 ms to ramp up/down to speed
#define TACHO_STOP_MODE     TACHO_BRAKE             // TACHO_COAST, TACHO_BRAKE, TACHO_HOLD
#define TACHO_RUN_MODE      TACHO_RUN_FOREVER       // TACHO_RUN_TO_REL_POS, TACHO_RUN_FOREVER

#define HEAD_MOTOR_TYPE     LEGO_EV3_M_MOTOR
#define HEAD_MAX_SPEED      50
#define HEAD_RAMPTIME_MS    10
#define HEAD_STOP_MODE      TACHO_BRAKE
#define HEAD_RUN_MODE       TACHO_RUN_FOREVER
#define HEAD_STOPPED_SLACK  2						// Change in readings to indicate that head has stopped

	.extern	usleep

	/** WAIT_500US
	 *
	 *    Macro to call usleep for 500 us
	 *
	 * Parameters:
	 *   None
	 * Returns:
	 *   r0: 0 if successful, -1 if error (errno set)
	 *
	 **/
	.macro	WAIT_500US
	ldr     r0, =SLEEP_DURATION_500US
	bl      usleep
	.endm

/** WAIT_3MS
 *
 *    Macro to call usleep for 3 ms
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: 0 if successful, -1 if error (errno set)
 *
 **/
	.macro	WAIT_3MS
	ldr     r0, =SLEEP_DURATION_3MS
	bl      usleep
	.endm

/** WAIT_10MS
 *
 *    Macro to call usleep for 10 ms
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: 0 if successful, -1 if error (errno set)
 *
 **/
	.macro	WAIT_10MS
    ldr     r0, =SLEEP_DURATION_10MS
    bl      usleep
	.endm

	.extern	prog_contentX

/** DISPLAY_ROBOT_STATE
 *
 *    Macro to Display status on LCD screen
 *
 * Parameters:
 *   status_str: Address of output string
 * Returns:
 *   None
 *
 **/
	.macro	DISPLAY_ROBOT_STATE	status_str
    ldr     r0, =\status_str
    mov		r1, #ROBOT_STATE_ROW
    bl      prog_contentX
	.endm

/** DISPLAY_DEBUG_INT
 *
 *    Macro to Display Integer Debug Info on LCD screen
 *
 * Parameters:
 *   debug_str: Address of Debug string
 *   int_reg:   Integer Value Register
 * Returns:
 *   None
 *
 **/
	.macro	DISPLAY_DEBUG_INT	debug_str int_reg
	push 	{\int_reg}
	ldr     r0, =\debug_str
	mov		r1, #ROBOT_DEBUG_ROW
	bl      prog_contentX
	pop		{r0}
	mov		r1, #DEBUG_INT_WIDTH
	bl		prog_display_integer_aligned
	.endm

#endif
