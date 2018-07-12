/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  tachotest.S
 *  \brief  ARM-based Tacho Motor (LEGO Large Servo Motor) example.
 *			Controls the first detected Large Servo Motor.
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "ev3_tacho.h"
#include "ev3dev-arm-bbr.h"

#undef  BRUTE_FORCE_TIMING

#define TACHO_MOTOR_TYPE 	LEGO_EV3_L_MOTOR		// Change to LEGO_EV3_M_MOTOR for Medium Servo Motor
#define TACHO_MAX_SPEED 	200						// Be careful not to set too large a number
#define TACHO_RAMPTIME_MS	100						// 100 ms to ramp up/down to speed
#define TACHO_STOP_MODE		TACHO_BRAKE				// TACHO_COAST, TACHO_BRAKE, TACHO_HOLD

	.data
	.align

printstr:		.asciz "Tacho Motor Test\n(LEGO Large Servo Motor)\n"
waittachostr:	.asciz "Waiting for Tacho Motor...\n"
foundtachostr:	.asciz "Found Tacho Motor at index: "
loopstr:		.asciz "Remaining loops: "

// Need to align the following data, otherwise the string termination is not guaranteed (output routine bug?)
	.align
countperrot:	.word	0					// Tacho count per rotation (360 deg)
prevposition:	.word	0					// Previous position of the tacho motor
currposition:	.word	0					// Current position of the tacho motor
seqno:			.byte	0					// Sequence number for motor type


	.code 32
	.text
	.align

wait_500ms:
	push	{lr}
	ldr		r0, =SLEEP_DURATION_500MS
	bl		usleep
	pop		{pc}

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
	bne		found_motor						// Motor not found
	bl		wait_500ms
	b		find_motor						// Delay 500 ms, try again
found_motor:
	pop		{pc}

stop_tacho:
	push	{lr}
	ldr		r0, =seqno
	ldrb	r0, [r0]						// setup motor sequence number
	mov		r1, #TACHO_STOP					// stop motor
	bl		set_tacho_command_inx
	pop		{pc}


/**
 *   Main application routine
 *
 *   Variables:
 *        R4: seqno value
 *        R5: Loop Counter value
 *        R6: Prev. Position Pointer
 *        R7: Curr. Position Pointer
 *        R8: countperrot value
 **/
	.global main
main:
	push	{lr}
	bl		prog_init
	ldr		r0, =printstr
	bl		prog_title
	bl		wait_500ms
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
	ldr		r8, =countperrot				// Pointer to variable
	ldr		r8, [r8]						// Retrieve count_per_rot value


	mov		r0, r4							// setup motor sequence number
	mov		r1, r8							// setup countperrot value
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
	ldr		r6, =prevposition				// Pointer to prevposition
	ldr		r7, =currposition				// Pointer to currposition

loop:
	ldr		r0, =loopstr
	bl		prog_content2

	mov		r0, r5							// Display loop counter
	mov		r1, #2							// Right aligned 2 digit counter
	bl		prog_display_integer_aligned

	mov		r0, r4							// setup motor sequence number
	mov		r1, r6							// Return value pointer
	bl		get_tacho_position				// Take original position reading

	mov		r0, r4							// setup motor sequence number
	mov		r1, #TACHO_RUN_TO_REL_POS		// move relative to current position
	bl		set_tacho_command_inx

wait_destpos:
#ifdef BRUTE_FORCE_TIMING
	// Brute force wait (time-based)
	ldr		r0, =SLEEP_DURATION_2SEC		// Delay 2 second
	bl		usleep
	ldr		r0, =SLEEP_DURATION_2SEC		// Delay 2 second
	bl		usleep
#else
	// Closed loop wait (Position-monitoring based)
	ldr		r0, =SLEEP_DURATION_100MS
	bl		usleep							// Check ever 100 ms

	mov		r0, r4							// setup motor sequence number
	mov		r1, r7							// Return value pointer
	bl		get_tacho_position				// Take new position reading

	ldr		r0, [r7]						// Curr Position
	ldr		r1, [r6]						// Prev Position
	add		r2, r1, r8						// targetposition = prevposition + countperrot
	cmp		r0, r2							// (currposition - targetposition) < 0?
	blt		wait_destpos						// have not reached the target, wait
#endif

	subs	r5, r5, #1						// Continue until done
	bne		loop

exit:
	bl		stop_tacho
	bl		prog_exit
	pop		{pc}

	.end
