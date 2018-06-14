/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  tachotest.S
 *  \brief  ARM-based Tacho Motor (LEGO Large Servo Motor) example.
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "ev3_tacho.h"
#include "ev3dev-arm-bbr.h"

#define TACHO_MOTOR_TYPE 	LEGO_EV3_L_MOTOR		// Change to LEGO_EV3_M_MOTOR for Medium Servo Motor
#define TACHO_MAX_SPEED 	25						// Be careful not to set too large a number
#define TACHO_RAMPTIME_MS	500					// 500 ms to ramp up/down to speed
#define TACHO_STOP_MODE		TACHO_HOLD				// TACHO_COAST, TACHO_BRAKE, TACHO_HOLD

	.equiv  MS_TO_US_MULTIPLIER, 1000
	.equiv	SLEEP_DURATION_100MS, 100 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_500MS, 500 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_1SEC, 1000 * MS_TO_US_MULTIPLIER
	.equiv	NUM_LOOPS, 10

	.extern usleep        /* C Library usleep() */

	.data
	.align

printstr:		.asciz "Tacho Motor (LEGO Large Servo Motor) Test\n"
waittachostr:	.asciz "Waiting for Tacho Motor...\n"
foundtachostr:	.asciz "Found Tacho Motor at index: "
loopstr:		.asciz "Remaining loops: "

countperrot:	.word	0					// Tacho count per rotation (360 deg)
seqno:			.byte	0					// Sequence number for motor type


	.code 32
	.text
	.align

init_tacho:
	push	{lr}
	bl		ev3_tacho_init
	cmp		r0, #0
	bge		find_motor
	ldr		r0, =SLEEP_DURATION_1SEC
	bl		usleep
	b		init_tacho						// Loop until tacho motors detected
find_motor:
	mov		r0, #TACHO_MOTOR_TYPE
	ldr		r1, =seqno						// pointer to seqno variable
	mov		r2, #0
	bl		ev3_search_tacho				// Search for TACHO_MOTOR_TYPE starting from motor0, return found flag
	cmp		r0, #FALSE
	beq		find_motor						// Motor not found
found_motor:
	pop		{pc}

	.global main
main:
	push	{lr}
	bl		prog_init
	ldr		r0, =printstr
	bl		prog_title
	ldr		r0, =SLEEP_DURATION_500MS
	bl		usleep
	ldr		r0, =waittachostr
	bl		prog_content1
	bl		init_tacho

tacho_setup:
	ldr		r0, =foundtachostr
	bl		prog_content1
	ldr		r4, =seqno
	ldrb	r4, [r4]						// read seqno U8 from memory into r4
	mov		r0, r4							// setup motor sequence number
	bl		prog_display_integer

	mov		r0, r4							// setup motor sequence number
	ldr		r1, =countperrot				// Pointer to variable
	bl		get_tacho_count_per_rot			// retrieve count per rotation

	mov		r0, r4							// setup motor sequence number
	ldr		r1, =countperrot				// Pointer to variable
	ldr		r1, [r1]						// Retrieve count_per_rot value
	bl		set_tacho_position_sp			// Setup target position for motor motion (one full rotation)

	mov		r0, r4							// setup motor sequence number
	ldr		r1, =TACHO_RAMPTIME_MS			// Ramp up duration (ms)
	bl		set_tacho_ramp_up_sp
	mov		r0, r4							// setup motor sequence number
	ldr		r1, =TACHO_RAMPTIME_MS			// Ramp down duration (ms)
	bl		set_tacho_ramp_down_sp

	mov		r0, r4							// setup motor sequence number
	mov		r1, #TACHO_MAX_SPEED			// Target speed of  motor
	bl		 set_tacho_speed_sp

	mov		r0, r4							// setup motor sequence number
	mov		r1, #TACHO_STOP_MODE			// How to stop the motor
	bl		 set_tacho_stop_action_inx

	mov		r5, #NUM_LOOPS					// Setup loop count
loop:
	ldr		r0, =loopstr
	bl		prog_content2

	mov		r0, r5							// Display loop counter
	bl		prog_display_integer

	mov		r0, r4							// setup motor sequence number
	mov		r1, #TACHO_RUN_TO_REL_POS		// move relative to current position
	bl		set_tacho_command_inx

	ldr		r0, =SLEEP_DURATION_1SEC		// Delay 1 second
	bl		usleep

	subs	r5, r5, #1						// Continue until done
	bne		loop

exit:
	bl		prog_exit
	pop		{pc}

	.end
