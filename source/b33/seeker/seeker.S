/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  seeker.S
 *  \brief  ARM-based seeker robot.
 *          Actuators/Motors:
 *              One Medium Servo Motor must be attached to port OUTPUT_A.
 *              Two Large Servo Motor must be attached to ports OUTPUT_B and OUTPUT_C.
 *              OUTPUT_B is the Left Motor while OUTPUT_C is the Right Motor.
 *          Sensors:
 *              Touch Sensor must be attached (any port)
 *              Color Sensor must be attached (any port)
 *
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "ev3_both.h"
#include "ev3_port.h"
#include "ev3_tacho.h"
#include "ev3_sensor.h"
#include "../b33.h"

// Compilation Debugging Switches
#undef DEBUG_MIN_MAX
#define DEBUG_LOOPCOUNT_EXCEEDED


/* Standard C Library routines */
	.extern	random									// <stdlib.h>
	.extern srandom									// <stdlib.h>
	.extern getpid									// <unistd.h>

/* Min-max routine */
	.extern min_max_u32

/*****************************************************************************/
/* Program Specific Defines
/*****************************************************************************/
    // Number of LEGO MINDSTORM Sensors
    .equiv  NUM_SENSORS, 2
     // Total number of LEGO MINDSTORM Large and Medium Servo Motors
    .equiv  NUM_ACTUATORS, 3
    // Number of LEGO MINDSTORM Large Servo Motors
    .equiv  NUM_MOTORS, 2
    // Scaling factor in no. of right bitshifts for countperrot (ASR 2 == div. 4 [90 deg])
    .equiv  ROTATION_SCALING, 2

    // Color Sensor Parameters
	.equiv	NUM_COLOR_READINGS, 5
	.equiv	SIZE_COLOR_READING, 4								// 32-bit values
	.equiv	COLOR_READ_INTERVAL, 3 * TICKS_PER_MSEC				// 3 ms

/*****************************************************************************/
/* Enums
/*****************************************************************************/
    // Robot State Enums
    ENUM_0		ROBOT_QUIT
    ENUM_N		ROBOT_IDLE
    ENUM_N		ROBOT_LOWER_HEAD
    ENUM_N		ROBOT_FOLLOW_PATH
    ENUM_N		ROBOT_ESCAPE

    // Movement Enums
    ENUM_0		MOVE_STOP
    ENUM_N		MOVE_FORWARD
    ENUM_N		MOVE_REVERSE
    ENUM_N		MOVE_LEFT
    ENUM_N		MOVE_RIGHT

    // Head Position Enums
    ENUM_0		HEAD_DOWN
    ENUM_N		HEAD_UP
    ENUM_N		HEAD_MOVING_DOWN
    ENUM_N		HEAD_MOVING_UP
    ENUM_N		HEAD_UNKNOWN

    .data
    .align
/*****************************************************************************/
/* Text Strings
/*****************************************************************************/

titlestr:       .asciz  "Seeker Robot"
waittachostr:	.asciz	"Detecting tacho motors......."
waitltachostr:  .asciz  "Waiting (Left Tacho Port B)  "
waitrtachostr:  .asciz  "Waiting (Right Tacho Port C) "
waitheadstr:    .asciz  "Waiting (Head Motor any port)"

foundmotor0str:	.asciz  "Tacho: L("
foundmotor1str:	.asciz  "), R("
foundmotor2str: .asciz  "), H("
foundmotorNstr: .asciz  ")  "

waitsensorstr:  .asciz  "Detecting sensors....."
waittouchstr:   .asciz  "Waiting (Touch Sensor)"
waitcolorstr:   .asciz  "Waiting (Color Sensor)"

foundsensor0str: .asciz	"Input: TCH("
foundsensor1str: .asciz	"), CLR("
foundsensorNstr: .asciz	")     "


// Behavior Status Strings
behavior_idlestr:       .asciz "Idle       "
behavior_lowerheadstr:  .asciz "Lower Head "
behavior_followpathstr: .asciz "Follow Path"
behavior_escapestr:     .asciz "Escape     "
exitstr:				.asciz "Exiting Seeker"

// Debug Strings

#ifdef DEBUG_LOOPCOUNT_EXCEEDED
exceeded_loopcnt_str:	.asciz "Exceeded Count: "
#endif

/** Motor Control Data Structure
 *
 **/
	.macro MOTOR_CONTROL_STRUCT	side
	.align
	// Speed control variables
	// The struct layout groups similar sized variables to optimize space allocation with data alignment
motor_control_struct_\side:
motor_speed_\side:		.word	0
motor_enable_\side: 	.byte	FALSE
motor_forward_\side:	.byte	FALSE
motor_numsteps_\side:	.byte	0

	 // The equates using .equ can be set by multiple macro invocations
	.equ motor_control_struct_size, . - motor_control_struct_\side
	.equ motor_speed_offset, motor_speed_\side - motor_control_struct_\side
	.equ motor_enable_offset, motor_enable_\side - motor_control_struct_\side
	.equ motor_forward_offset, motor_forward_\side - motor_control_struct_\side
	.equ motor_numsteps_offset, motor_numsteps_\side - motor_control_struct_\side
	.endm

// Need to align the following data, otherwise the string termination is not guaranteed
    .align
/*****************************************************************************/
/* Program Specific Variables (word aligned)
/*****************************************************************************/
/* Timing and Systick related parameters */
loop_systick:	.word	0					// System Event Loop Starting Systick value
loop_exceeded:	.word	0					// System Event Loop Duration Exceed Count

color_last_systick:	.word	0				// Color Sensor Last Reading Systick value

/* Touch Sensor Parameters */
touch_val:		.word	0					// Touch sensor input buffer

/* Color Sensor Parameters */
color_intensity_min:   .word 0
color_intensity_max:   .word 0
color_intensity_array: .space	(NUM_COLOR_READINGS * SIZE_COLOR_READING), 0x0		// 32-bit values

/* Head Motor Position Parameters */
head_prevpos:	.word	0
head_currpos:	.word	0

/* Limb Motor Coroutine synchronization variable */
num_running_motors: .word    0

/* Motor Rotation related parameter */
countperrot:    .word   0                   // Tacho count per rotation (360 deg)
                                            // Assume identical for both limb motors

/*****************************************************************************/
/* Motor Actuator speed control structs (word aligned)
/*****************************************************************************/
	MOTOR_CONTROL_STRUCT	head
	MOTOR_CONTROL_STRUCT	left
	MOTOR_CONTROL_STRUCT	right

#if 1
// Check macro constant name expansion
	.align
mcs_size:			.word		motor_control_struct_size
mcs_speed_offset:	.word		motor_speed_offset
mcs_enable_offset:	.word		motor_enable_offset
mcs_forward_offset:	.word		motor_forward_offset
mcs_numsteps_offset: .word		motor_numsteps_offset
#endif
/*****************************************************************************/
/* Program Specific Variables (byte aligned)
/*****************************************************************************/
	.align
/* EV3 Keypress input variable */
keypress:		.byte	EV3_KEY__NONE_

/* Sting Activated state variable */
sting_activated: .byte	FALSE

/* Head Movement state variable */
head_state:		.byte	HEAD_UNKNOWN

/* Robot State variable */
robot_state:	.byte	ROBOT_IDLE

/* Behavior Suppression Boolean */
bhvr_suppress:	.byte	TRUE

/*****************************************************************************/
/* Device Sequence Numbers used by ev3dev-c
/*****************************************************************************/

/* Vector of seqnos needed by multi_set_tacho_XXX()
 *    The data structure is arranged as a nested structure
 *    actuators_vec include all motors for the robot, while
 *    motors_vec includes the limb motors.
 *    The vector terminator is shared by both vectors
 */
/* Vector of all actuator motors (including head and limb motors) */
actuators_vec:
seqno_head:     .byte   0
/* Vector of all limb motors */
motors_vec:
seqno_right:    .byte   0                   // Sequence number for right motor
seqno_left:     .byte   0                   // Sequence number for left motor
endmotors:      .byte   DESC_LIMIT          // Vector Terminator

    .equiv      motors_vec_len, . - motors_vec
    .equiv		actuators_vec_len, . - actuators_vec

seqno_touch:    .byte   0
seqno_color:    .byte   0

/*****************************************************************************/
/* motor_xxxx Coroutine Macro Definition
/*****************************************************************************/
/** motor_xxxx Couroutine Macro
 *
 * Template for coroutine instantiation
 *
 * Implements:
 *    count_xxxx: number of rotation arcs per 360 deg rotation
 *    tacho_enable_xxxx: motor is activated
 *    tacho_direction_xxxx: forward or reverse motion
 *    tacho_currpos_xxxx: current reading of encoder for motor
 *    tacho_targetpos_xxxx: target reading of encoder for motor
 *    has_tacho_reached_target_xxxx(): check function for wait primitive
 *    motor_config_xxxx(): function to configure motor, and tacho_targetpos_xxxx
 *    motor_xxxx(): coroutine body
 *
 * Requires (external functions and variables):
 *    countperrot: value for number of encoder clicks per 360 deg rotation
 *    advance_tacho_target_position(): function to update tacho_targetpos_xxxx
 *    num_running_motors: for rendezvous point checking
 *    has_no_running_motors(): Rendezvous Point check function
 *    seqno_xxxx: Motor Sequence Number
 *    start_tacho(): function to start motor and increment num_running_motors
 *    stop_tacho(): function to stop motor and decrement num_running_motors
 *
 **/
    .macro      DEFINE_COROUTINE_MOTOR    side

    // Coroutine Variables for motor_\side
    .data
    .align
    CORO_LOCAL      tacho_enable_\side, byte, 0
    CORO_LOCAL      tacho_forward_\side, byte, 0
    CORO_LOCAL		count_\side, byte, 0

    .align
    CORO_LOCAL		tacho_currpos_\side, word, 0
    CORO_LOCAL		tacho_targetpos_\side, word, 0
    CORO_LOCAL		tacho_speed_\side, word, 0

    CORO_CONTEXT    motor_\side

    // Coroutine helper functions and body
    .code 32
    .text
    .align

	/** has_tacho_reached_target_xxxx
	 *
	 *   Has Tacho Reached Target Position?
	 *   Check function for Coroutine motor_xxxx
	 *
     * Returns:
     *   r0: TRUE if target position reached, FALSE otherwise
	 *
	 **/
has_tacho_reached_target_\side:
    push    {r4, lr}
    ldr     r0, =seqno_\side
    ldrb    r0, [r0]                        // Retrieve motor sequence number
    ldr     r4, =tacho_currpos_\side
    mov     r1, r4                          // Setup parameter
    bl      get_tacho_position              // Record current position for motor_\side

    ldr     r0, [r4]                        // Retrieve current position
    ldr     r1, =tacho_targetpos_\side
    ldr     r1, [r1]                        // Target Position for motor_\side

    ldr		r2, =tacho_forward_\side		// Retrieve forward direction flag (boolean)
    ldrb	r2, [r2]
    cmp		r2, #FALSE
    beq		check_reverse_\side

check_forward_\side:
    cmp     r0, r1                          // (currposition - targetposition) < 0?
    movge   r0, #TRUE
    movlt   r0, #FALSE
    pop     {r4, pc}

check_reverse_\side:
    cmp     r0, r1                          // (currposition - targetposition) > 0?
    movle   r0, #TRUE
    movgt   r0, #FALSE
    pop     {r4, pc}


	/** motor_config_xxxx
	 *
	 * Parameters:
	 *   r0: enable (bool)
	 *   r1: forward (bool)
	 * Returns:
	 *   r0: TRUE if (num_running_motors == 0), else FALSE
	 */
motor_config_\side:
    push    {lr}
    ldr		r2, =tacho_enable_\side			// Setup enable flag
    strb    r0, [r2]
    ldr     r2, =tacho_forward_\side		// Setup forward (direction) flag
    strb    r1, [r2]
    ldr     r0, =seqno_\side
    ldrb    r0, [r0]                        // Retrieve sequence number
    ldr     r1, =tacho_targetpos_\side
    bl      get_tacho_position              // Record initial target tacho position
    pop     {pc}

	/** motor_xxxx
	 *
	 * Coroutine Body
	 *
	 */
    CORO_START  motor_\side

	ldr		r0, =tacho_enable_\side			// Retrieve tacho_enable_\side boolean
	ldrb	r0, [r0]
	cmp		r0, #FALSE
	beq		motor_end_\side					// Skip coroutine execution if motor is disabled

    ldr     r1, =count_\side
    // determine no. of times to move motor using scaled rotation angle (subset of 360 deg)
    mov     r0, #(1 << ROTATION_SCALING)
    strb    r0, [r1]

advance_\side:
    ldr     r1, =tacho_targetpos_\side
    ldr		r2, =countperrot
    ldr		r2, [r2]						// Retrieve unsigned countperrot value
    ldr		r3, =tacho_speed_\side
    ldr		r3, [r3]						// Speed of the motor

    // Use r0 (temporary) to check tacho_forward_\side
    ldr		r0, =tacho_forward_\side		// Retrieve tacho_forward_\side boolean
	ldrb	r0, [r0]
	cmp		r0, #FALSE						// Check if the value needs to be complemented
	bne		update_target_\side				// tacho_forward_\side is TRUE, so skip

	// Reverse motion
	rsb		r2, r2, #0						// Calculate 2's complement for r1 (r1 := 0 - r1)
	rsb		r3, r3, #0						// Calculate 2's complete for r3 (r3 := 0 - r3)

update_target_\side:
    mov     r2, r2, asr #ROTATION_SCALING   // setup scaled countperrot value
    ldr     r0, =seqno_\side
    ldrb    r0, [r0]                        // Setup motor sequence number
    bl      set_targetpos_and_start_tacho   // Set new target and start motor

    CORO_WAIT   has_tacho_reached_target_\side

    ldr     r0, =seqno_\side
    ldrb    r0, [r0]                        // Setup motor sequence number
    bl      stop_tacho                      // Stop motor

    // Rendezvous Point
    CORO_WAIT   has_no_running_motors       // Don't let one motor get ahead of the other(s)
    CORO_YIELD                              // Must allow the other motor(s) to synchronize

    ldr     r1, =count_\side
    ldrb    r0, [r1]
    subs    r0, r0, #1
    strb    r0, [r1]
    bne     advance_\side                    // Not done with 360 deg rotation yet

motor_end_\side:
    CORO_END

    .endm
/*****************************************************************************/

/** set_bhvr_suppress
 *
 *    Macro to set bhvr_suppress
 *
 * Parameters:
 *   flag: Boolean (TRUE or FALSE)
 * Returns:
 *   None
 *
 * Registers r0 and r1 are modified
 *
 **/
	.macro	set_bhvr_suppress	condition
	ldr		r1, =bhvr_suppress
	mov		r0, #\condition
	strb	r0, [r1]
	.endm

/** get_bhvr_suppress
 *
 *    Macro to get bhvr_suppress
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: bhvr_suppress (TRUE or FALSE)
 *
 **/
	.macro	get_bhvr_suppress
	ldr		r0, =bhvr_suppress
	ldrb	r0, [r0]
	.endm


/** DEFINE_BEHAVIOR_ROUTINE
 *
 *	  Used to define Behaviors
 *
 *    Need to provide:
 *    - trigger_\behavior routine that returns TRUE if behavior should be activated
 *    - Coroutine Context \behavior to store behavior state
 *    - Coroutine \behavior to execute behavior tasks
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
 	.macro	DEFINE_BEHAVIOR_ROUTINE behavior
bhvr_\behavior:
	push	{lr}
	get_bhvr_suppress				// r0: Supressed flag (Boolean)
	cmp		r0, #FALSE
	beq		check_\behavior			// Not suppressed, so skip reset

reset_\behavior:
	CORO_CONTEXT_INIT \behavior		// reset behavior coroutine
	b		exit_\behavior

check_\behavior:
	bl		trigger_\behavior		// Check activation conditions
	cmp		r0, #FALSE
	beq		exit_\behavior			// Not activated, so skip coroutine call

call_\behavior:
	CORO_CALL	\behavior
	set_bhvr_suppress TRUE			// Suppress other behaviors

exit_\behavior:
	pop		{pc}

	.endm


/** record_systick
 *
 *    Macro to store current systick to systick_var
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 * Registers r0 and r1 are modified
 *
 **/
	.macro	record_systick	systick_var
	bl		tick_systick				// returns current systick in r0
 	ldr		r1, =\systick_var
 	str		r0, [r1]					// record systick for current reading
	.endm

    .code 32
    .text
    .align
/*****************************************************************************/
/* Utiilty Functions to support sensor_xxxx Coroutines
/*****************************************************************************/
/** has_color_interval_elapsed
 *
 *    Last Color Sensor Reading Interval Check
 *
 *    Note: We need to deal with U32 rollover issues using signed arithmetic
 *          color_last_systick and current systick are both U32
 *          Sleep if (S32)( current systick - next color_last_systick ) < 0
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: TRUE if reading interval exceeded, else FALSE
 *
 **/
has_color_interval_elapsed:
    push    {lr}
	bl		tick_systick					// returns current systick in r0

	ldr		r1, =color_last_systick
	ldr		r2, =COLOR_READ_INTERVAL
	ldr		r3, [r1]						// Retrieve Color Sensor last reading systick
	add		r3, r3, r2						// New Color Sensor read time
	cmp		r0, r3							// Compare current sytick to target color sensor read time
	movlt	r0, #FALSE
	movge	r0, #TRUE
	pop		{pc}

/*****************************************************************************/
/* Utiilty Functions to support motor_xxxx Coroutine Macros
/*****************************************************************************/

/** has_no_running_motors
 *
 *    Rendezvous Point check function for motor_xxxx coroutine
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: TRUE if (num_running_motors == 0), else FALSE
 *
 **/
has_no_running_motors:
    ldr     r0, =num_running_motors
    ldr     r0, [r0]
    teq     r0, #0
    moveq   r0, #TRUE
    movne   r0, #FALSE
    mov     pc, lr


/** advance_tacho_target_position
 *
 * Parameters:
 *    r0: pointer to tacho target position
 *    r1: signed target position delta (forward/reverse)
 * Returns:
 *   None
 */
advance_tacho_target_position:
    ldr     r2, [r0]                        // old target position
    // new target position = old target position + signed target position delta
    add     r2, r2, r1
    str     r2, [r0]                        // store new target position
    mov     pc, lr

/** set_targetpos_and_start_tacho
 *
 * Parameters:
 *   r0: motor sequence number
 *   r1: pointer to tacho target position
 *   r2: signed relative position delta
 *   r3: signed speed
 * Returns:
 *   None
 */
set_targetpos_and_start_tacho:
    push    {r4, r5, lr}
    mov     r4, r0                          // keep motor sequence number
    mov		r5, r3							// keep signed speed

	// Setup tacho target position
    ldr     r0, [r1]                        // old target position
    // new target position = old target position + signed relative position delta
    add     r0, r0, r2
    str     r0, [r1]                        // store new target position
    bl      set_tacho_position_sp

    // Setup motor speed
    mov     r0, r4                          // retrieve motor sequence number
    mov		r1, r5							// retrieve signed speed
    bl      set_tacho_speed_sp

	// Start motor
    mov     r0, r4                          // retrieve motor sequence number
    mov     r1, #TACHO_RUN_MODE             // configure run mode
    bl      set_tacho_command_inx

    // increment num_running_motors
    ldr     r1, =num_running_motors
    ldr     r0, [r1]
    add     r0, r0, #1
    str     r0, [r1]
    pop     {r4, r5, pc}

/** stop_tacho
 *
 * Parameters:
 *    r0: motor sequence number
 * Returns:
 *   None
 */
stop_tacho:
    push    {lr}
    mov     r1, #TACHO_STOP                 // stop motor
    bl      set_tacho_command_inx
    ldr     r1, =num_running_motors
    ldr     r0, [r1]
    sub     r0, r0, #1
    str     r0, [r1]                        // decrement num_running_motors
    pop     {pc}

/*****************************************************************************/
/* Utiilty Functions to support Head Actuator Movement
/*****************************************************************************/
/** record_head_position
 *
 * Parameters:
 *    r0: Pointer to Head Position variable
 * Returns:
 *   None
 */
record_head_position:
    push    {lr}
	mov		r1, r0							// Needed as second argument
    ldr     r0, =seqno_head
    ldrb    r0, [r0]                        // Retrieve head sequence number
    bl      get_tacho_position              // Record starting position for head motor
    pop     {pc}

/** has_head_stopped
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: TRUE if stopped, else FALSE
  */
has_head_stopped:
    push    {lr}
	// Record current position
    ldr     r0, =head_currpos
    bl      record_head_position            // Record starting position for head motor

    ldr     r0, =head_currpos
    ldr		r0, [r0]
    ldr     r2, =head_prevpos
    ldr		r1, [r2]
	subs	r1, r0, r1						// r1 = currpos - prevpos
	neglt	r1, r1							// get absolute difference
	cmp		r1, #HEAD_STOPPED_SLACK			// Allow for some slack in readings
	bls		head_stopped

head_still_moving:
	str		r0, [r2]						// Update prevpos with currpos reading
	mov		r0, #FALSE						// Return status
	b		exit_has_head_stopped

head_stopped:
	mov		r0, #TRUE						// Return status

exit_has_head_stopped:
    pop     {pc}

/*****************************************************************************/
/* Utiilty Functions to setup Actuator Controller for Behavior Coroutines
/*****************************************************************************/
/** config_motor_stop
 *
 * Parameters:
 *    r0: Pointer to Motor Control Structure
 * Returns:
 *   None
 */
config_motor_stop:
    mov		r1, #FALSE
    strb	r1, [r0, #motor_enable_offset]
    mov		pc, lr

/** config_motor_forward
 *
 * Parameters:
 *    r0: Pointer to Motor Control Structure
 *    r1: Speed
 *    r2: Number of steps (used by limb motors)
 * Returns:
 *   None
 */
config_motor_forward:
    str		r1, [r0, #motor_speed_offset]
	strb	r2, [r0, #motor_numsteps_offset]
    mov		r3, #TRUE
    strb	r3, [r0, #motor_enable_offset]
    strb	r3, [r0, #motor_forward_offset]
    mov		pc, lr

/** config_motor_reverse
 *
 * Parameters:
 *    r0: Pointer to Motor Control Structure
 *    r1: Speed
 *    r2: Number of steps (used by limb motors)
 * Returns:
 *   None
 */
config_motor_reverse:
    str		r1, [r0, #motor_speed_offset]
	strb	r2, [r0, #motor_numsteps_offset]
    mov		r3, #TRUE
    strb	r3, [r0, #motor_enable_offset]
    mov		r3, #FALSE
    strb	r3, [r0, #motor_forward_offset]
    mov		pc, lr

/*****************************************************************************/
/* Coroutine Instantiation
/*****************************************************************************/
    DEFINE_COROUTINE_MOTOR left
    DEFINE_COROUTINE_MOTOR right

/*****************************************************************************/
/** motor_head
 *
 * Coroutine for Head Control
 *
 */
    // Coroutine Variables for motor_head
    .data
    .align
    CORO_LOCAL   head_pos, byte, 0

    .align
 	CORO_CONTEXT motor_head

    .code 32
    .text
    .align

 	CORO_START	motor_head
 	NOP
 	CORO_END

/*****************************************************************************/
/** sensor_color
 *
 * Coroutine for Color Sensor Inputs
 *
 */
    // Coroutine Variables for sensor_color
    .data
    .align
    CORO_LOCAL	 color_index, byte, 0

    .align
 	CORO_CONTEXT sensor_color

    .code 32
    .text
    .align

 	CORO_START	sensor_color

 	ldr		r1, =color_index
 	mov		r0, #NUM_COLOR_READINGS
 	strb	r0, [r1]					// initialize color_index


 next_color_reading:
 	push	{r4, r5}					// preserve temporary variable registers
 	ldr		r5, =color_index
 	ldrb	r4, [r5]					// retrieve color_index into r4
 	sub		r4, r4, #1					// point to current index
 	strb	r4, [r5]					// update current color_index in memory

	record_systick color_last_systick	// record systick for current color sensor reading
 	mov		r0, #0						// value index
 	ldr		r1, =seqno_color
 	ldr		r2, =color_intensity_array
	add		r2, r2, r4, lsl #2			// setup address pointer for input value (index for 32-bit integer)
 	bl		get_sensor_value

	cmp		r4, #0						// have we collected all of them?
 	pop		{r4, r5}					// restore temporary variable registers
 	beq		done_sensor_color

wait_next_reading:
 	CORO_WAIT	has_color_interval_elapsed
 	b		next_color_reading

done_sensor_color:
 	CORO_END

/*****************************************************************************/
/** sensor_touch
 *
 * Coroutine for Touch Sensor Inputs
 *
 */
    // Coroutine Variables for sensor_touch
    .data
    .align
 	CORO_CONTEXT sensor_touch

    .code 32
    .text
    .align

 	CORO_START	sensor_touch
    mov     r0, #0
    ldr		r1, =seqno_touch				// pointer to touch sensor sequence number
    ldrb	r1, [r1]						// touch sensor sequence number
    ldr		r2, =touch_val					// pointer to touch_val
    bl		get_sensor_value

    // Set sting_activated variable if touched
    ldr		r1, =sting_activated
    ldr		r2, =touch_val					// pointer to touch_val
	ldr		r0, [r2]						// Retrieve Touch value
	cmp		r0, #FALSE
	beq		no_sting

	mov		r0, #TRUE
	strb	r0, [r1]						// Only set state variable, cleared by behavior
no_sting:
 	CORO_END

/*****************************************************************************/
/** Behavior Coroutine escape
 *
 * Coroutine for Behavior escape
 *
 */
    // Coroutine Variables
    .data
    .align
 	CORO_CONTEXT escape

    .code 32
    .text
    .align

    // Trigger routine
    // Returns TRUE if conditions met, FALSE otherwise
trigger_escape:
	ldr		r1, =sting_activated
	ldrb	r0, [r1]
	cmp		r0, #FALSE
	movne	r0, #TRUE						// Touch Activated, so flag TRUE
	mov		pc, lr

 	CORO_START	escape

loop_escape:
	DISPLAY_ROBOT_STATE behavior_escapestr
	// Raise Head
	// FIXME: current head state is not checked

	// Record staring position
    ldr     r0, =head_prevpos
    bl      record_head_position            // Record starting position for head motor

	ldr		r1, =head_state
	mov		r0, #HEAD_MOVING_UP
	strb	r0, [r1]						// Update head state variable

	// Setup Head Controller actions
	ldr		r0, =motor_control_struct_head
	mov		r1, #HEAD_MAX_SPEED
	mov		r2, #0							// Num steps is not used by Head Controller
	bl		config_motor_forward			// Start Head Motor movement

	ldr		r1, =head_state					// Update Head State variable
	mov		r0, #HEAD_MOVING_UP
	strb	r0, [r1]

	// Move X steps forward
	bl		random							// Generate a random value in r0
	and		r2, r0, #0x3					// Keep last 2 bits as step count (0-3)
	add		r2, r2, #1						// make sure there is at least one step (1-4)
	mov		r0, #MOVE_FORWARD
	ldr		r1, =TACHO_MAX_SPEED
	bl		movement_selector				// Setup movement
	CORO_YIELD

check_escape_done:
	push	{r4, r5}						// Needed to track has_head_stopped() and has_no_running_motors()
	bl		has_head_stopped
	mov		r4, r0							// r4: has_head_stopped status
	bl		has_no_running_motors
	mov		r5, r0							// r5: 	has_no_running_motors status

check_head_position:
	cmp		r4, #TRUE
	bne		escape_not_done					// Escape behavior has not completed yet

head_has_stopped:
	ldr		r2, =head_state					// Update Head State variable
	ldrb	r1, [r2]						// Get current Head State
	mov		r0, #HEAD_UP
	cmp		r0, r1							// Have we updated state previously?
	beq		check_motor_done				// yes, so skip update

	// Stop Motor if we have not done so yet
	strb	r0, [r2]						// Set Head State to UP
	ldr		r0, =motor_control_struct_head
	bl		config_motor_stop				// Stop Head Motor movement

check_motor_done:
	cmp		r5, #TRUE
	beq		escape_done						// Behavior Completed

escape_not_done:
	pop		{r4, r5}						// Clean up stack
	CORO_YIELD
	b	check_escape_done					// Behavior not done yet, keep looping

 escape_done:
	pop		{r4, r5}						// Clean up stack
  	// Clear sting_activated state variable
 	ldr		r1, =sting_activated
 	mov		r0, #FALSE
 	strb	r0, [r1]

 	CORO_END

/*****************************************************************************/
/** Behavior Coroutine followpath
 *
 * Coroutine for Behavior followpath
 *
 */
    // Coroutine Variables
    .data
    .align
 	CORO_CONTEXT followpath

    .code 32
    .text
    .align

    // Trigger routine
    // Returns TRUE if conditions met, FALSE otherwise
trigger_followpath:
	push	{lr}
	mov		r0, #FALSE
	pop		{pc}

 	CORO_START	followpath
loop_followpath:
	DISPLAY_ROBOT_STATE behavior_followpathstr
	CORO_YIELD
	b	loop_followpath
 	CORO_END

/*****************************************************************************/
/** Behavior Coroutine lower_head
 *
 * Coroutine for Behavior lower_head
 *
 */
    // Coroutine Variables
    .data
    .align
 	CORO_CONTEXT lower_head

    .code 32
    .text
    .align

    // Trigger routine
    // Returns TRUE if conditions met, FALSE otherwise
trigger_lower_head:
	push	{lr}
	mov		r0, #FALSE
	pop		{pc}

 	CORO_START	lower_head
loop_lower_head:
	DISPLAY_ROBOT_STATE behavior_lowerheadstr
	CORO_YIELD
	b		loop_lower_head
 	CORO_END

/*****************************************************************************/
/** Behavior Coroutine idle
 *
 * Coroutine for Behavior idle
 *
 */
    // Coroutine Variables
    .data
    .align
 	CORO_CONTEXT idle

    .code 32
    .text
    .align

 	CORO_START	idle

loop_idle:
	DISPLAY_ROBOT_STATE behavior_idlestr
	ldr		r0, =motor_control_struct_head
	bl		config_motor_stop
	// Use movement routine to setup actuator controller
	mov		r0, #MOVE_STOP
	bl		movement_selector				// Setup movement

#if 0
	ldr		r0, =motor_control_struct_left
	bl		config_motor_stop
	ldr		r0, =motor_control_struct_right
	bl		config_motor_stop
#endif
	CORO_YIELD
	b		loop_idle
 	CORO_END


/*****************************************************************************/
/* Behavior Routines
/*****************************************************************************/

    .code 32
    .text
    .align

	DEFINE_BEHAVIOR_ROUTINE escape		// Highest priority
	DEFINE_BEHAVIOR_ROUTINE followpath
	DEFINE_BEHAVIOR_ROUTINE lower_head

/*****************************************************************************/
/** bhvr_idle
 *    Idle Behavior (Lowest Priority)
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
bhvr_idle:
	push	{lr}
	get_bhvr_suppress				// r0: Supressed flag (Boolean)
	cmp		r0, #TRUE
	beq		exit_idle

call_idle:
	CORO_CONTEXT_INIT	idle		// Reset idle context
	CORO_CALL	idle				// Always activates

exit_idle:
	pop		{pc}

/*****************************************************************************/
/* Actuator Routines
/*****************************************************************************/

    .code 32
    .text
    .align

/*****************************************************************************/
/** movement_selector
 *
 *   Setup Limb Movement based on enum input
 *
 *   MOVE_STOP    0: stop movement (default)
 *   MOVE_FORWARD 1: straight ahead (both motor forward)
 *   MOVE_REVERSE 2: straight back (both motor reverse)
 *   MOVE_LEFT    3: circle to the left (right motor forward)
 *   MOVE_RIGHT   4: circle to the right (left motor forward)
 *
 *   NOTE: Customize according to robot design
 *
 * Parameters:
 *   r0: Movement type Enum
 *   r1: Movement Speed
 *   r2: Number of Steps
 * Returns:
 *   None
 *
 **/
movement_selector:
	push	{lr}

enum_check:
	cmp		r0, #MOVE_FORWARD
	beq		move_forward
	cmp		r0, #MOVE_REVERSE
	beq		move_reverse
	cmp		r0, #MOVE_LEFT
	beq		move_left
	cmp		r0, #MOVE_RIGHT
	beq		move_right

default_movement:
	// r0 == MOVE_STOP or unknown value
	ldr		r0, =motor_control_struct_left
	bl		config_motor_stop
	ldr		r0, =motor_control_struct_right
	bl		config_motor_stop
	b		exit_movement_selector

move_forward:
	// Enable both motors forward
	ldr		r0, =motor_control_struct_left
	bl		config_motor_forward
	ldr		r0, =motor_control_struct_right
	bl		config_motor_forward
	b		exit_movement_selector

move_reverse:
	// Enable both motors reverse
	ldr		r0, =motor_control_struct_left
	bl		config_motor_reverse
	ldr		r0, =motor_control_struct_right
	bl		config_motor_reverse
	b		exit_movement_selector

move_left:
	// Disable left motor, enable right motor forward
	ldr		r0, =motor_control_struct_left
	bl		config_motor_stop
	ldr		r0, =motor_control_struct_right
	bl		config_motor_forward
	b		exit_movement_selector

move_right:
	// Enable left motor forward, disable right motor
	ldr		r0, =motor_control_struct_left
	bl		config_motor_forward
	ldr		r0, =motor_control_struct_right
	bl		config_motor_stop
	// b		exit_movement_selector

#if 0

move_forward_check:
    cmp		r0, #MOVE_FORWARD
    bne		move_reverse_check
	// Enable Left Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_left
    // Enable Right Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_right
	b		exit_movement_selector

move_reverse_check:
    cmp		r0, #MOVE_REVERSE
    bne		move_left_check
	// Enable Left Motor Reverse
    mov		r0, #TRUE
    mov		r1, #FALSE
    bl		motor_config_left
    // Enable Right Motor Reverse
    mov		r0, #TRUE
    mov		r1, #FALSE
    bl		motor_config_right
	b		exit_movement_selector

move_left_check:
    cmp		r0, #MOVE_LEFT
    bne		move_right_check
	// Disable Left Motor
    mov		r0, #FALSE
    mov		r1, #FALSE
    bl		motor_config_left
    // Enable Right Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_right
	b		exit_movement_selector

move_right_check:
    cmp		r0, #MOVE_RIGHT
    bne		move_stop
	// Enable Left Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_left
    // Disable Right Motor
    mov		r0, #FALSE
    mov		r1, #FALSE
    bl		motor_config_right
	b		exit_movement_selector

move_stop:
	// Disable Left Motor
    mov		r0, #FALSE
    mov		r1, #FALSE
    bl		motor_config_left
    // Disable Right Motor
    mov		r0, #FALSE
    mov		r1, #FALSE
    bl		motor_config_right
#endif

exit_movement_selector:
	pop		{pc}

/** actuator_head
 *    head actuator controller
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
actuator_head:
    push    {lr}
    pop     {pc}

/** actuator_limbs
 *    left and right limb actuator controller
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
actuator_limbs:
    push    {lr}
    pop     {pc}


/*****************************************************************************/
/** wait_500ms
 *    500 ms delay routine
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
wait_500ms:
    push    {lr}
    ldr     r0, =SLEEP_DURATION_500MS
    bl      usleep
    pop     {pc}

/** display_motor_info
 *    Output motor index at row specified by prog_content1
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
display_motor_info:
    push    {lr}
    ldr     r0, =foundmotor0str
    bl      prog_content1

    ldr     r1, =seqno_left
    ldrb    r0, [r1]                        // read left motor seqno U8 from memory into r0
    bl      prog_display_integer

    ldr     r0, =foundmotor1str
    bl      prog_display_string

    ldr     r1, =seqno_right
    ldrb    r0, [r1]                        // read right motor seqno U8 from memory into r0
    bl      prog_display_integer

    ldr     r0, =foundmotor2str
    bl      prog_display_string

    ldr     r1, =seqno_head
    ldrb    r0, [r1]                        // read head motor seqno U8 from memory into r0
    bl      prog_display_integer

    ldr     r0, =foundmotorNstr
    bl      prog_display_string
 	pop		{pc}

/** display_sensor_info
 *    Output sensor index at row specified by prog_content2
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
display_sensor_info:
	push	{lr}
    ldr     r0, =foundsensor0str
    bl      prog_content2

    ldr     r1, =seqno_touch
    ldrb    r0, [r1]                        // read touch seqno U8 from memory into r0
    bl      prog_display_integer

    ldr     r0, =foundsensor1str
    bl      prog_display_string

    ldr     r1, =seqno_color
    ldrb    r0, [r1]                        // read color seqno U8 from memory into r0
    bl      prog_display_integer

    ldr     r0, =foundsensorNstr
    bl      prog_display_string
    pop     {pc}


/** init_sensors
 *
 *   Initialize Sensor Subsystem
 *
 *   NOTE: Customize according to robot design
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
init_sensors:
    push    {lr}
detect_sensor:
    bl      ev3_sensor_init                  // Returns number of sensors detected
    cmp		r0, #NUM_SENSORS
    bge		find_touch_sensor

    ldr     r0, =waitsensorstr
    bl      prog_content2
    ldr     r0, =SLEEP_DURATION_1SEC
    bl      usleep
    b       detect_sensor                    // Loop until at least one sensor detected

find_touch_sensor:
    ldr     r0, =waittouchstr
    bl      prog_content2

    mov     r0, #LEGO_EV3_TOUCH
    ldr		r1, =seqno_touch
    mov     r2, #0
    bl      ev3_search_sensor				// Search for touch sensor starting from 0, TRUE if found
    cmp     r0, #FALSE
    beq     detect_sensor                   // Not found, try again from the beginning

find_color_sensor:
	ldr		r0, =waitcolorstr
	bl		prog_content2

    mov     r0, #LEGO_EV3_COLOR
    ldr		r1, =seqno_color
    mov     r2, #0
    bl      ev3_search_sensor				// Search for touch sensor starting from 0, TRUE if found
    cmp     r0, #FALSE
    beq     detect_sensor                   // Not found, try again from the beginning

found_sensors:
	bl		display_sensor_info
    pop	    {pc}

/** setup_sensors
 *
 *   Configure Sensor Settings
 *
 *   NOTE: Customize according to robot design
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
 setup_sensors:
    push    {lr}
	ldr		r0, =seqno_color
	ldrb	r0, [r0]
	mov		r1, #COLOR_COL_REFLECT
	bl		set_sensor_mode_inx				// Configure Color Sensor for reflected light intensity input
    pop	    {pc}

/** init_motors
 *
 *   Initialize Motor Subsystem
 *
 *   Setup actuators for two TACHO_MOTOR_TYPE Motors
 *   attached to L_MOTOR_PORT and R_MOTOR_PORT respectively.
 *
 *   Setup actuator for HEAD_MOTOR_TYPE, attached to any port
 *
 *   NOTE: Customize according to robot design
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
init_motors:
    push    {lr}
detect_tacho:
    bl      ev3_tacho_init                  // Returns number of motors detected
    cmp     r0, #NUM_ACTUATORS
    bge     find_l_motor

    ldr     r0, =waittachostr
    bl      prog_content1
    ldr     r0, =SLEEP_DURATION_1SEC
    bl      usleep
    b       detect_tacho                    // Loop until tacho motors detected

find_l_motor:
    mov     r0, #TACHO_MOTOR_TYPE
    mov     r1, #L_MOTOR_PORT
    mov     r2, #L_MOTOR_EXT_PORT
    ldr     r3, =seqno_left
    // Search for TACHO_MOTOR_TYPE attached to L_MOTOR_PORT, return found flag
    bl      dvcs_search_tacho_type_for_port 
    cmp     r0, #FALSE
    bne     find_r_motor
    ldr     r0, =waitltachostr
    bl      prog_content1
    bl      ev3_tacho_init                  // Not found, reinitialize ev3_tacho desc
    bl      wait_500ms
    b       find_l_motor                    // Delay 500 ms, try again

find_r_motor:
    mov     r0, #TACHO_MOTOR_TYPE
    mov     r1, #R_MOTOR_PORT
    mov     r2, #R_MOTOR_EXT_PORT
    ldr     r3, =seqno_right
    // Search for TACHO_MOTOR_TYPE attached to R_MOTOR_PORT, return found flag
    bl      dvcs_search_tacho_type_for_port 
    cmp     r0, #FALSE
    bne     find_head_motor
    ldr     r0, =waitrtachostr
    bl      prog_content1
    bl      ev3_tacho_init                  // Not found, reinitialize ev3_tacho desc
    bl      wait_500ms
    b       find_r_motor                    // Delay 500 ms, try again

find_head_motor:
    mov     r0, #HEAD_MOTOR_TYPE
    ldr     r1, =seqno_head
    mov		r2, #0							// starting seqno
	// Search for TACHO_MOTOR_TYPE starting from motor0, return found flag
	bl		ev3_search_tacho
	cmp		r0, #FALSE
	bne		found_motors					// Motor not found
    ldr     r0, =waitheadstr
    bl      prog_content1
    bl      ev3_tacho_init                  // Not found, reinitialize ev3_tacho desc
	bl		wait_500ms
	b		find_head_motor					// Delay 500 ms, try again

found_motors:
	bl		display_motor_info
    pop     {pc}

/** setup_motors
 *
 *   Configure Motor Settings for limb and head motors
 *
 *   NOTE: Customize according to robot design
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
setup_motors:
    push    {r4, r5, lr}

    // Limb motor configuration
    ldr     r4, =countperrot                // Pointer to variable
    ldr     r5, =motors_vec                 // setup motor vector

    // Retrieve countperrot value from left motor
    ldr     r0, =seqno_left
    ldrb    r0, [r0]                        // read left motor seqno U8 from memory into r0
    mov     r1, r4
    bl      get_tacho_count_per_rot         // retrieve count per rotation

    // Setup Ramp/Up down duration (ms)
    mov     r0, r5                          // motor vector address for function call
    ldr     r1, =TACHO_RAMPTIME_MS          // Ramp up duration (ms)
    bl      multi_set_tacho_ramp_up_sp

    mov     r0, r5                          // motor vector address for function call
    ldr     r1, =TACHO_RAMPTIME_MS          // Ramp down duration (ms)
    bl      multi_set_tacho_ramp_down_sp

    // Setup motor stop mode
    mov     r0, r5                          // motor vector address for function call
    mov     r1, #TACHO_STOP_MODE            // How to stop the motor
    bl      multi_set_tacho_stop_action_inx

	// Head motor configuration
	ldr		r0, =seqno_head
	ldrb	r4, [r0]						// read head motor seqno U8 from memory into r4

    // Setup Ramp/Up down duration (ms)
    mov		r0, r4							// head seqno
    ldr     r1, =HEAD_RAMPTIME_MS           // Ramp up duration (ms)
    bl      set_tacho_ramp_up_sp

    mov		r0, r4							// head seqno
    ldr     r1, =HEAD_RAMPTIME_MS           // Ramp up duration (ms)
    bl      set_tacho_ramp_down_sp

   // Setup head stop mode
    mov     r0, r4                          // head seqno
    mov     r1, #HEAD_STOP_MODE             // How to stop the motor
    bl      set_tacho_stop_action_inx

    pop     {r4, r5, pc}

/** stop_and_release_motors
 *
 *   Stop and Release Motor Brakes
 *
 *   Disable Brake Locks if previously configured
 *   to allow the motors to coast (move when rotated).
 *
 *   This routine will affect all three attached motors.
 *
 *   NOTE: Customize according to robot design
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
stop_and_release_motors:
    push    {lr}
    ldr     r0, =actuators_vec              // setup actuators vector
    mov     r1, #TACHO_STOP                 // set run mode
    bl      multi_set_tacho_command_inx
    ldr     r0, =actuators_vec              // setup actuators vector
    mov     r1, #TACHO_COAST                // release motor
    bl      multi_set_tacho_stop_action_inx
    pop     {pc}

/** update_systick_and_sleep
 *
 *   Update event loop systick and sleep until start of next loop.
 *
 *   WARNING: The event loop assumes that all routines are completed within
 *            EVENTLOOP_TICKCOUNT, otherwise the event loop behavior will not
 *            be predictable.
 *
 *   Note: We need to deal with U32 rollover issues using signed arithmetic
 *         loop_systick and current systick are both U32
 *         Sleep if (S32)( current systick - next loop_systick ) < 0
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
update_systick_and_sleep:
	push	{r4, lr}

	bl		tick_systick					// returns current systick in r0
	ldr		r1, =loop_systick
	ldr		r4, =EVENTLOOP_TICKCOUNT
	ldr		r3, [r1]						// get current loop starting systick
	add		r3, r3, r4						// r3 = next loop starting systick (may rollover)
	subs	r2, r0, r3						// check (r2 = (current systick - next loop_systick)) < 0
	bge		no_sleep						// false, so no sleeping
	neg		r2, r2							// 2's complement of negative duration in r2
	cmp		r2, r4
	bhs		no_sleep						// Sleep Duration is greater than EVENTLOOP_TICKCOUNT

go_sleep:
	str		r3, [r1]						// Update next loop starting systick
	mov		r0, r2							// Setup usleep duration
	bl		usleep							// Call usleep()
	b		exit_sleep

no_sleep:
	str		r0, [r1]						// Store current systick as the start of the next event loop
	ldr		r1, =loop_exceeded
	ldr		r0, [r1]
	add		r0, r0, #1
	str		r0, [r1]						// Update loop_exceeded count

#ifdef DEBUG_LOOPCOUNT_EXCEEDED
	DISPLAY_DEBUG_INFO exceeded_loopcnt_str r0
#endif

exit_sleep:
	pop		{r4, pc}

/** init_robot
 *
 *   Initialize Robot Sensors and Actuators
 *
 *   NOTE: Customize according to robot design
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
init_robot:
    push    {lr}
    bl		tick_init
    bl      init_sensors
    bl      init_motors
    bl		setup_sensors
    bl      setup_motors
    bl		getpid							// Retrieve the PID of the process, as srandom seed
	bl		srandom							// Initialize random number generator

	// Setup Robot State to ROBOT_IDLE
	mov		r0, #ROBOT_IDLE
	ldr		r1, =robot_state
	strb	r0, [r1]

    pop     {pc}

#if 0

// WARNING: This routine somehow hangs the program
// In addition, it is not necessary to use it since the Back button will exit the currently running program
// launched from Brickman if press and held for 2 seconds

/** check_exit
 *
 *   Check status of button to see if it is being pressed.
 *
 *   Note: ev3_read_keys check the instantaneous keypress state.
 *         It does not remember / buffer previous key presses
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: TRUE if exit pressed, FALSE if not
 *
 **/
check_exit:
	push	{lr}
	ldr		r0, =keypress					// Buffer address for keypress
	bl		ev3_read_keys					// Check if key pressed
	ldr		r0, =keypress
	ldrb	r0, [r0]						// Retrieve keypress
	cmp		r0, #EV3_KEY__NONE_
	beq		done_exit_check					// Return FALSE (EV3_KEY__NONE_)

check_back_pressed:
	ands	r0, r0, #EV3_KEY_BACK			// Single bit bitmask
	beq		done_exit_check					// Return FALSE if bit cleared (== 0)

back_key_pressed:
	mov		r0, #TRUE						// Back key pressed, return TRUE

done_exit_check:
	pop		{pc}

#endif

/*****************************************************************************/

/** input_controller
 *
 *   Poll all inputs and check key presses
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 * Register r4 is used as coroutine loop sensor coroutine counter
 **/
input_controller:
    push    {r4, lr}

/************************ Begin Customization Here ***************************/

	CORO_CONTEXT_INIT sensor_color			// reset color input gathering
	CORO_CONTEXT_INIT sensor_touch			// reset touch input gathering

input_coroutine_dispatcher:
	mov		r4, #NUM_SENSORS				// Number of sensor inputs to process

#if 0
check_keypress:
	bl		check_exit
	cmp		r0, #TRUE
	beq		flag_robot_quit
#endif

check_color_sensor:
	CORO_CALL	sensor_color
	cmp		r0, #CO_END
    subeq   r4, r4, #1
	bne		check_touch_sensor

calc_min_max:
	ldr		r0, =color_intensity_array
	mov		r1, #NUM_COLOR_READINGS
	ldr		r2, =color_intensity_min
	ldr		r3, =color_intensity_max
	bl		min_max_u32						// perform min-max calculation

check_touch_sensor:
	CORO_CALL	sensor_touch
	cmp		r0, #CO_END
    subeq   r4, r4, #1

input_coroutine_continue:
	cmp		r4, #0
	beq		exit_input_controller			// Done with all the sensor inputs

	wait_500us								// Let task scheduler do something else
	b		input_coroutine_dispatcher		// continue with next event loop

flag_robot_quit:
	ldr		r1, =robot_state
	mov		r0, #ROBOT_QUIT
	strb	r0, [r1]

/************************* End Customization Here ****************************/
exit_input_controller:
	pop		{r4, pc}

/** behavior_dispatcher
 *
 *   Incorporates behavior dispatcher and arbiter
 *
 *   This version implements fixed priority hierarchical arbitration
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
behavior_dispatcher:
    push    {lr}

/************************ Begin Customization Here ***************************/

	bl		bhvr_escape
	bl		bhvr_followpath
	bl		bhvr_lower_head
	bl		bhvr_idle			// Idle should always be the lowest priority behavior

/************************* End Customization Here ****************************/

	set_bhvr_suppress	FALSE	// Clear bhvr_suppress flag
	pop		{pc}

/** actuator_controller
 *
 *   Configure all actuator outputs
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
actuator_controller:
    push    {lr}

/************************ Begin Customization Here ***************************/

	bl		actuator_head
	bl		actuator_limbs

/************************* End Customization Here ****************************/

	pop		{pc}

/*****************************************************************************/

/** main
 *
 *   Main application routine
 *
 * Variables:
 *   R4: pointer to robot_state
 **/
    .global main
main:
    push    {lr}
    bl      prog_init
    ldr     r0, =titlestr
    bl      prog_title
    bl      wait_500ms

/************************ Begin Customization Here ***************************/
robot_setup:
    bl      init_robot                      // Setup sensor and motor modules

	// Configure robot_state
	ldr		r4, =robot_state
	mov		r0, #ROBOT_IDLE
	strb	r0, [r4]

	// Suppress all behaviors on first pass to reset behaviors
	set_bhvr_suppress	TRUE

	// Configure loop_systick before starting event loop
	record_systick loop_systick

event_loop:

	bl		input_controller				// Update sensor and keypress inputs

	// Check if we need to quit
	ldr		r0, [r4]
	cmp		r0, #ROBOT_QUIT
	beq		robot_cleanup					// Quit detected

	bl		behavior_dispatcher				// Execute behaviors based on priority
	bl		actuator_controller				// Configure actuator outputs

event_sleep:
	bl		update_systick_and_sleep		// Sleep for remainder of event loop
    b       event_loop

robot_cleanup:
	DISPLAY_ROBOT_STATE exitstr
    bl      stop_and_release_motors

/************************* End Customization Here ****************************/

exit_main:
    bl      prog_exit
    mov		r0, #0							// Exit status
    pop     {pc}

    .end
