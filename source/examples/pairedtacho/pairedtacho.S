/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  pairedtacho.S
 *  \brief  ARM-based Dual Tacho Motor (LEGO Large Servo Motor) example.
 *			Two Large Servo Motor must be attached to ports OUTPUT_B and OUTPUT_C.
 *			OUTPUT_B is the Left Motor while OUTPUT_C is the Right Motor.
 *			The motors will rotate for NUM_LOOPS rotations, but each motor will not start
 *			on the next rotation until both motors have completed their respective rotation for the loop.
 *
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "ev3_both.h"
#include "ev3_port.h"
#include "ev3_tacho.h"
#include "ev3dev-arm-bbr.h"

#undef  BRUTE_FORCE_TIMING

#define L_MOTOR_PORT      OUTPUT_B
#define L_MOTOR_EXT_PORT  EXT_PORT__NONE_
#define R_MOTOR_PORT      OUTPUT_C
#define R_MOTOR_EXT_PORT  EXT_PORT__NONE_

#define TACHO_MOTOR_TYPE 	LEGO_EV3_L_MOTOR		// Change to LEGO_EV3_M_MOTOR for Medium Servo Motor
#define TACHO_MAX_SPEED 	200						// Be careful not to set too large a number
#define TACHO_RAMPTIME_MS	100						// 100 ms to ramp up/down to speed
#define TACHO_STOP_MODE		TACHO_BRAKE				// TACHO_COAST, TACHO_BRAKE, TACHO_HOLD

	.equiv  MS_TO_US_MULTIPLIER, 1000
	.equiv	SLEEP_DURATION_10MS,   10 * MS_TO_US_MULTIPLIER
	.equiv	SLEEP_DURATION_100MS, 100 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_500MS, 500 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_1SEC, 1000 * MS_TO_US_MULTIPLIER
	.equiv  SLEEP_DURATION_2SEC, 2000 * MS_TO_US_MULTIPLIER
	.equiv	NUM_LOOPS, 10

	.extern usleep        /* C Library usleep() */

	.data
	.align

printstr:		.asciz "Paired Tacho Motor Test\n(LEGO Large Servo Motors)\n"
waitltachostr:	.asciz 		"Waiting (Left Tacho Port B) \n"
waitrtachostr:	.asciz 		"Waiting (Right Tacho Port C)\n"
foundlefttachostr:	.asciz 	"Tacho: Left ("
foundrighttachostr:	.asciz 	"), Right ("
foundtachoendstr:   .asciz  ")   "
loopstr:		.asciz "Remaining loops: "

// Need to align the following data, otherwise the string termination is not guaranteed (output routine bug?)
	.align
countperrot:	.word	0					// Tacho count per rotation (360 deg)		// Assume identical for both motoros
prevrposition:	.word	0					// Previous position of the right tacho motor
prevlposition:	.word	0					// Previous position of the left tacho motor
currrposition:	.word	0					// Current position of the right tacho motor
currlposition:	.word	0					// Current position of the left tacho motor

motors_vec:									// Vector of motor seqnos needed by multi_set_tacho_XXX()
rightseqno:		.byte	0					// Sequence number for right motor
leftseqno:		.byte	0					// Sequence number for left motor
endmotors:		.byte	DESC_LIMIT			// Vector Terminator

	.equiv		motors_vec_len, . - motors_vec

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
	bge		find_l_motor
	ldr		r0, =SLEEP_DURATION_1SEC
	bl		usleep
	b		init_tacho						// Loop until tacho motors detected

find_l_motor:
	ldr		r0, =waitltachostr
	bl		prog_content1
	mov		r0, #TACHO_MOTOR_TYPE
	mov		r1, #L_MOTOR_PORT
	mov		r2, #L_MOTOR_EXT_PORT
	ldr		r3, =leftseqno
	bl		dvcs_search_tacho_type_for_port	// Search for TACHO_MOTOR_TYPE attached to L_MOTOR_PORT, return found flag
	cmp		r0, #FALSE
	bne		find_r_motor
	bl		wait_500ms
	b		find_l_motor					// Delay 500 ms, try again

find_r_motor:
	ldr		r0, =waitrtachostr
	bl		prog_content1
	mov		r0, #TACHO_MOTOR_TYPE
	mov		r1, #R_MOTOR_PORT
	mov		r2, #R_MOTOR_EXT_PORT
	ldr		r3, =rightseqno
	bl		dvcs_search_tacho_type_for_port	// Search for TACHO_MOTOR_TYPE attached to R_MOTOR_PORT, return found flag
	cmp		r0, #FALSE
	bne		found_motors
	bl		wait_500ms
	b		find_r_motor					// Delay 500 ms, try again

found_motors:
	ldr		r0, =foundlefttachostr
	bl		prog_content1

	ldr		r4, =leftseqno
	ldrb	r4, [r4]						// read seqno U8 from memory into r4
	mov		r0, r4							// setup left motor sequence number
	bl		prog_display_integer

	ldr		r0, =foundrighttachostr
	bl		prog_display_string

	ldr		r5, =rightseqno
	ldrb	r5, [r5]						// read seqno U8 from memory into r5
	mov		r0, r5							// setup right motor sequence number
	bl		prog_display_integer

	ldr		r0, =foundtachoendstr
	bl		prog_display_string
	pop		{pc}

stop_lefttacho:
	push	{lr}
	ldr		r0, =leftseqno
	ldrb	r0, [r0]						// setup motor sequence number
	mov		r1, #TACHO_STOP					// stop motor
	bl		set_tacho_command_inx
	pop		{pc}

stop_righttacho:
	push	{lr}
	ldr		r0, =rightseqno
	ldrb	r0, [r0]						// setup motor sequence number
	mov		r1, #TACHO_STOP					// stop motor
	bl		set_tacho_command_inx
	pop		{pc}

release_tachos:
	push	{lr}
	ldr		r0, =motors_vec					// setup motor vector
	mov		r1, #TACHO_COAST				// release motor
	bl		multi_set_tacho_stop_action_inx
	pop		{pc}


/**
 *   Main application routine
 *
 *   Variables:
 *        R4: left seqno value
 *        R5: right seqno value
 *        R6: Loop Counter value
 *        R7: Prev. left Position Pointer
 *        R8: Curr. left Position Pointer
 *        R9: Prev. right Position Pointer
 *        R10: Curr. right Position Pointer
 *        R11: countperrot value
 *		  R12: No of running motors
 **/
	.global main
main:
	push	{lr}
	bl		prog_init
	ldr		r0, =printstr
	bl		prog_title
	bl		wait_500ms

	bl		init_tacho						// r4 and r5 setup with left and right tacho seqnos

tacho_setup:
	ldr		r11, =countperrot				// Pointer to variable

	mov		r0, r4							// setup motor sequence number
	mov		r1, r11							// Pointer to variable
	bl		get_tacho_count_per_rot			// retrieve count per rotation
	ldr		r11, [r11]						// Load count_per_rot value

	// Setup target position for motor rotation (one full rotation)
	ldr		r0, =motors_vec					// setup motor vector
	mov		r1, r11							// setup countperrot value
	bl		multi_set_tacho_position_sp			// Setup target position

	// Setup Ramp/Up down duration (ms)
	ldr		r0, =motors_vec					// setup motor vector
	ldr		r1, =TACHO_RAMPTIME_MS			// Ramp up duration (ms)
	bl		multi_set_tacho_ramp_up_sp

	ldr		r0, =motors_vec					// setup motor vector
	ldr		r1, =TACHO_RAMPTIME_MS			// Ramp down duration (ms)
	bl		multi_set_tacho_ramp_down_sp

	// Setup motor speed
	ldr		r0, =motors_vec					// setup motor vector
	mov		r1, #TACHO_MAX_SPEED			// Target speed of  motor
	bl		multi_set_tacho_speed_sp

	// Setup motor stop mode
	ldr		r0, =motors_vec					// setup motor vector
	mov		r1, #TACHO_STOP_MODE			// How to stop the motor
	bl		multi_set_tacho_stop_action_inx

	mov		r6, #NUM_LOOPS					// Setup loop count
	ldr		r7, =prevlposition				// Pointer to prevlposition
	ldr		r8, =currlposition				// Pointer to currlposition
	ldr		r9, =prevrposition				// Pointer to prevrposition
	ldr		r10, =currrposition				// Pointer to currrposition

// FIXME: Need to support dual motors
loop:
	ldr		r0, =loopstr
	bl		prog_content2

	mov		r0, r6							// Display loop counter
	mov		r1, #2							// Right aligned 2 digit counter
	bl		prog_display_integer_aligned

	// Setup number of running motors
	mov		r12, #2							// 2 motors are running

	mov		r0, r4							// setup left motor sequence number
	mov		r1, r7							// Return value pointer
	bl		get_tacho_position				// Take original left position reading

	mov		r0, r5							// setup right motor sequence number
	mov		r1, r9							// Return value pointer
	bl		get_tacho_position				// Take original right position reading

	ldr		r0, =motors_vec					// setup motor vector
	mov		r1, #TACHO_RUN_TO_REL_POS		// move relative to current position
	bl		multi_set_tacho_command_inx

wait_destpos:
#ifdef BRUTE_FORCE_TIMING
	// Brute force wait (time-based)
	ldr		r0, =SLEEP_DURATION_2SEC		// Delay 2 second
	bl		usleep
	ldr		r0, =SLEEP_DURATION_2SEC		// Delay 2 second
	bl		usleep
#else
	// Closed loop wait (Position-monitoring based)
	ldr		r0, =SLEEP_DURATION_10MS
	bl		usleep							// Check ever 100 ms

	mov		r0, r4							// setup left motor sequence number
	mov		r1, r8							// Return value pointer
	bl		get_tacho_position				// Take new left position reading

	mov		r0, r5							// setup right motor sequence number
	mov		r1, r10							// Return value pointer
	bl		get_tacho_position				// Take new right position reading

check_left_tacho:
	ldr		r0, [r8]						// Curr left Position
	ldr		r1, [r7]						// Prev left Position
	add		r2, r1, r11						// targetposition = prevposition + countperrot
	cmp		r0, r2							// (currposition - targetposition) < 0?
	blt		check_right_tacho				// have not reached the target, check other motor
	bl		stop_lefttacho					// Don't let one motor get ahead of the other
	sub		r12, r12, #1					// one motor stopped

check_right_tacho:
	ldr		r0, [r10]						// Curr right Position
	ldr		r1, [r9]						// Prev right Position
	add		r2, r1, r11						// targetposition = prevposition + countperrot
	cmp		r0, r2							// (currposition - targetposition) < 0?
	blt		check_both_stopped				// have not reached the target, check other motor
	bl		stop_righttacho				// Don't let one motor get ahead of the other
	sub		r12, r12, #1					// one motor stopped


check_both_stopped:
	cmp		r12, #0							// have both motors stopped?
	bgt		wait_destpos					// At least one motor is still running

#endif

	subs	r6, r6, #1						// Continue until done
	bne		loop

exit:
	bl		release_tachos
	bl		prog_exit
	pop		{pc}

	.end
