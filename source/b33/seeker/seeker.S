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
#define USE_USLEEP
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
	// Number of rotation arcs per step
    .equiv	NUM_ARCS_PER_STEP, (1 << ROTATION_SCALING)

    // Color Sensor Parameters
	.equiv	NUM_COLOR_READINGS, 5
	.equiv	SIZE_COLOR_READING, 4								// 32-bit values

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
	// Motor Actuator parameters
	// The struct layout groups similar sized variables to optimize space allocation with data alignment
motor_control_struct_\side:
motor_speed_\side:		.word	0				// absolute value (magnitude only)
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


/** Limb Movement Control Data Structure
 *
 **/
	.macro LIMB_MOTOR_STRUCT	side
    .align
	// Limb Motor control variables
	// The struct layout groups similar sized variables to optimize space allocation with data alignment
limb_motor_struct_\side:
limb_currpos_\side:		.word	0
limb_targetpos_\side:	.word	0
sgn_limb_deltapos_\side:.word	0
sgn_limb_speed_\side:	.word	0
limb_forward_\side:		.byte	FALSE
limb_seqno_\side:		.byte	0				// Keep it in the struct to avoid using another pointer

	 // The equates using .equ can be set by multiple macro invocations
	.equ limb_control_struct_size, . - limb_motor_struct_\side
	.equ limb_currpos_offset, limb_currpos_\side - limb_motor_struct_\side
	.equ limb_targetpos_offset, limb_targetpos_\side - limb_motor_struct_\side
	.equ sgn_limb_deltapos_offset, sgn_limb_deltapos_\side - limb_motor_struct_\side
	.equ sgn_limb_speed_offset, sgn_limb_speed_\side - limb_motor_struct_\side
	.equ limb_forward_offset, limb_forward_\side - limb_motor_struct_\side
	.equ limb_seqno_offset, limb_seqno_\side - limb_motor_struct_\side
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
/* Motor Actuator speed control structs
/*****************************************************************************/
	MOTOR_CONTROL_STRUCT	head
	MOTOR_CONTROL_STRUCT	left
	MOTOR_CONTROL_STRUCT	right

	MOTOR_CONTROL_STRUCT	prev_head
	MOTOR_CONTROL_STRUCT	prev_left
	MOTOR_CONTROL_STRUCT	prev_right

#if 0
// Check macro constant name expansion
	.align
mcs_size:			.word		motor_control_struct_size
mcs_speed_offset:	.word		motor_speed_offset
mcs_enable_offset:	.word		motor_enable_offset
mcs_forward_offset:	.word		motor_forward_offset
mcs_numsteps_offset: .word		motor_numsteps_offset
#endif

/*****************************************************************************/
/* Limb Motor variables
/*****************************************************************************/
	LIMB_MOTOR_STRUCT		left
	LIMB_MOTOR_STRUCT		right

/*****************************************************************************/
/* Program Specific Variables (byte aligned)
/*****************************************************************************/
	.align
/*****************************************************************************/
/* Input related
/*****************************************************************************/

/* EV3 Keypress input variable */
keypress:		.byte	EV3_KEY__NONE_

/* Sting Activated state variable */
sting_activated: .byte	FALSE

/*****************************************************************************/
/* Behavior related
/*****************************************************************************/

/* Escape state variable */
escape_state:	.byte	ESCAPE_IDLE

/* Head Position state variable */
headpos_state:	.byte	HEADPOS_UNKNOWN

/*****************************************************************************/
/* Actuator related
/*****************************************************************************/

/* Head Movement state variable */
head_state:		.byte	HEAD_IDLE

/* Limb Movement state variable */
limb_state_left:  .byte	LIMB_IDLE
limb_state_right: .byte	LIMB_IDLE

/* Limb Actuator Movement Parameters */
limb_actuator_struct:						// Little Endian Packing (LSB to MSB)
step_count_left:  .byte	0					// Number of steps for left limb
arc_count_left:	  .byte	0					// Arcs per step for left limb
step_count_right: .byte	0					// Number of steps for right limb
arc_count_right:  .byte	0					// Arcs per step for right limb

	.equ	limb_actuator_struct_size, . - limb_actuator_struct

/*****************************************************************************/
/* System related
/*****************************************************************************/

/* Robot State variable */
robot_state:	.byte	ROBOT_IDLE

/* Behavior Suppression Boolean */
	DEFINE_BHVR_SUPPRESS

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

#if 0
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
 *    start_limb_tacho(): function to start motor and increment num_running_motors
 *    stop_limb_tacho(): function to stop motor and decrement num_running_motors
 *
 **/
#endif

/*****************************************************************************/
/** load_and_copy_motor_control_structs
 *
 *    Macro to load new and prev motor_control_structs, and copy
 *    new motor_control_structs to prev motor_control_structs
 *
 * Parameters:
 *   new_control_struct: Pointer to new control struct
 *   prev_control_struct: Pointer to
 * Returns:
 *   None
 *
 * Registers r0-r9 are modified
 *
 **/
	.macro	load_and_copy_motor_control_structs new_control_struct, prev_control_struct
 	ldr		r8, =\new_control_struct
 	ldr		r9, =\prev_control_struct

	// Current Motor Actuator settings
 	ldrb	r0, [r8, #motor_enable_offset]
 	ldr		r1, [r8, #motor_speed_offset]
 	ldrb	r2, [r8, #motor_numsteps_offset]
 	ldrb	r3, [r8, #motor_forward_offset]
 	// Previous Motor Actuator settings
 	ldrb	r4, [r9, #motor_enable_offset]
 	ldr		r5, [r9, #motor_speed_offset]
  	ldrb	r6, [r9, #motor_numsteps_offset]
  	ldrb	r7, [r9, #motor_forward_offset]
 	// Update Previous Motor Actuator settings with new requests
 	strb	r0, [r9, #motor_enable_offset]
 	str		r1, [r9, #motor_speed_offset]
 	strb	r2, [r9, #motor_numsteps_offset]
 	strb	r3, [r9, #motor_forward_offset]
	.endm

    .code 32
    .text
    .align

/** has_timer_expired
 *
 *    Timer Expiry Check
 *
 *    Note: We need to deal with U32 rollover issues using signed arithmetic
 *          timer expiry and current systick are both U32
 *          Sleep if (S32)( current systick - timer expiry ) < 0
 *
 * Parameters:
 *   r0: timer expiry (in systick counts) [U32]
 * Returns:
 *   r0: TRUE if reading interval exceeded, else FALSE
 *
 **/
has_timer_expired:
    push    {r4, lr}
    mov		r4, r0							// Keep timer expiry in r4
	bl		tick_systick					// returns current systick in r0
	cmp		r0, r4							// Compare current sytick to timer expiry time
	movlt	r0, #FALSE
	movge	r0, #TRUE
	pop		{r4, pc}

/*****************************************************************************/
/* Utiilty Functions to support motor_xxxx Coroutine Macros
/*****************************************************************************/

/** has_limb_reached_targetpos
 *
 *   Has Tacho Reached Target Position?
 *   Check function for Coroutine motor_xxxx
 *
 * Parameters:
 *    r0: pointer to limb motor control struct for \side
 * Returns:
 *   r0: TRUE if target position reached, FALSE otherwise
 *
 **/
has_limb_reached_targetpos:
    push    {r4, lr}
    mov		r4, r0							// Use r4 to access limb motor control struct
    ldrb    r0, [r4, #limb_seqno_offset]	// Retrieve motor sequence number
    add		r1, r4, #limb_currpos_offset	// Point to current position variable address
    bl      get_tacho_position				// Record current position for motor_\side

    ldr     r0, [r4, #limb_currpos_offset]	// Retrieve current position
    ldr     r1, [r4, #limb_targetpos_offset]// Target Position for motor_\side

    ldrb	r2, [r4, #limb_forward_offset]
    cmp		r2, #FALSE
    beq		check_reverse_targetpos

check_forward_targetpos:
    cmp     r0, r1                          // (currposition - targetposition) < 0?
    movge   r0, #TRUE
    movlt   r0, #FALSE
    pop     {r4, pc}

check_reverse_targetpos:
    cmp     r0, r1                          // (currposition - targetposition) > 0?
    movle   r0, #TRUE
    movgt   r0, #FALSE
    pop     {r4, pc}

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

/** set_targetpos_and_start_limb_tacho
 *
 * Parameters:
 *    r0: pointer to limb motor control struct for \side
 * Returns:
 *    None
 */
set_limb_targetpos_and_start_tacho:
    push    {r4, r5, lr}

	mov		r4, r0
	ldrb	r5, [r4, #limb_seqno_offset]		// retrieve limb motor seqno

	// Update tacho target position
    ldr     r1, [r4, #limb_targetpos_offset]	// old target position
    ldr		r2, [r4, #sgn_limb_deltapos_offset]
    // new target position = old target position + signed target position delta
    add     r1, r1, r2
    str     r1, [r4, #limb_targetpos_offset]	// store new target position

	// Setup tacho target position for motor
	mov		r0, r5								// setup parameter for function call
    bl      set_tacho_position_sp				// Setup tacho position for motor

	mov		r0, r5
	ldr		r1, [r4, #sgn_limb_speed_offset]
    bl      set_tacho_speed_sp

	// Start motor
    mov     r0, r5                          // retrieve motor sequence number
    mov     r1, #TACHO_RUN_MODE             // configure run mode
    bl      set_tacho_command_inx

    // increment num_running_motors
    ldr     r1, =num_running_motors
    ldr     r0, [r1]
    add     r0, r0, #1
    str     r0, [r1]

    pop     {r4, r5, pc}

/** update_and_check_steps_done
 *
 * Movement is counted in steps, which comprises of multiple arcs
 *
 *    Arc is decremented to zero
 *    If Arc is zero, then Step is decremented
 *
 * Parameters:
 *    r0: step count pointer
 *    r1: arc count pointer
 * Returns:
 *    r0: TRUE if movement done
 */
update_and_check_steps_done:
    push    {lr}
	ldrb	r2, [r0]						// Get step count
	ldrb	r3, [r1]						// Get arc count

	subs	r3, r3, #1
	strb	r3, [r1]						// Decrement arc count
	bgt		steps_not_done

arcs_done:
	subs	r2, r2, #1
	strb	r2, [r1]						// Decrement step count
	beq		steps_done						// If num steps is zero, movement is done

update_arc_count:
    mov     r0, #NUM_ARCS_PER_STEP
    strb	r0, [r1]						// Reload num arcs for next step
    b		steps_not_done

steps_done:
	mov		r0, #TRUE
    pop     {pc}

steps_not_done:
	mov		r0, #FALSE
    pop     {pc}


/** stop_limb_tacho
 *
 * Parameters:
 *    r0: limb motor sequence number
 * Returns:
 *    None
 */
stop_limb_tacho:
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

/** start_head_tacho
 *
 * Parameters:
 *    r0: forward (boolean)
 *    r1: speed (magnitude)
 * Returns:
 *    None
 */
start_head_tacho:
    push    {r4, lr}
    ldr		r4, =seqno_head
    ldrb	r4, [r4]

    // Setup motor speed
    cmp		r0, #TRUE						// is it forward
    negne	r1, r1							// 2's complement of speed if reverse

    mov     r0, r4                          // retrieve motor sequence number
    bl      set_tacho_speed_sp

	// Start motor
    mov     r0, r4                          // retrieve motor sequence number
    mov     r1, #HEAD_RUN_MODE             // configure run mode
    bl      set_tacho_command_inx
    pop     {r4, pc}

/** stop_head_tacho
 *
 * Parameters:
 *    None
 * Returns:
 *    None
 */
stop_head_tacho:
    push    {lr}
    ldr		r0, =seqno_head
    ldrb	r0, [r0]
    mov     r1, #TACHO_STOP                 // stop motor
    bl      set_tacho_command_inx
    pop     {pc}

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

/** is_escape_movement_done
 *
 * Parameters:
 *   None
 * Returns:
 *   r0: TRUE if stopped, else FALSE
  */
is_escape_movement_done:

#if 1
	// FIXME
	mov		r0, #TRUE
	mov		pc, lr
#else
/* This is too low level for behaviors to check
	ldr		r1, =limb_actuator_struct
	ldr		r0, [r1]						// contains byte values for num steps and num arcs
	cmp		r0, #0							// Check if it is all done
	moveq	r0, #TRUE						// No steps or arcs left, so we're done
	mov		pc, lr
*/

	ldr		r2, =limb_state_left
	ldr		r3, =limb_state_right
	ldrb	r0, [r2]						// Get Left Limb State
	ldrb	r1, [r3]						// Get Right Limb State

check_limb_states:
	cmp		r0, #LIMB_IDLE
	bne		flag_escape_not_done
	cmp		r1, #LIMB_IDLE
	beq		flag_escape_done

flag_escape_not_done:
	mov		r0, #FALSE
	mov		pc, lr

flag_escape_done:
	mov		r0, #TRUE
	mov		pc, lr
#endif


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
 *   r1: Movement Speed (magnitude)
 *   r2: Number of Steps
 * Returns:
 *   None
 *
 **/
movement_selector:
	push	{lr}

movement_enum_check:
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

/* WARNING: The following code assumes that r1-r2 are not destroyed by calling the subroutines */
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

exit_movement_selector:
	pop		{pc}

/** check_limb_waitsync_done
 *
 * Parameters:
 *    r0: Pointer to Limb State
 * Returns:
 *   None
 */

check_limb_waitsync_done:
	push	{r4, lr}
	mov		r4, r0							// Keep limb state pointer
	bl		has_no_running_motors
	cmp		r0, #TRUE
	bne		exit_limb_waitsync_done			// Some motors are still active, skip

update_limb_state_donesync:
	mov		r0, #LIMB_DONESYNC
	strb	r0, [r4]

exit_limb_waitsync_done:
	pop		{r4, pc}


/*****************************************************************************/
/* Literal Pool Instantiation
/*****************************************************************************/
	.ltorg

/*****************************************************************************/
/** actuator_head
 *
 * Coroutine for Head Control
 *
 * Note: Since we're using push/pop in the Coroutine, there should not be any CORO_* macro calls
 *       between the push and the pop instructions
 *
 *  If (head_state == HEAD_DONE)
 *      reset state to HEAD_IDLE
 *
 *  If (head_state == HEAD_IDLE)
 *	    // Ignore numsteps parameter
 *      Record Head Motor Position
 *
 *	    If (head.enabled != prev_head.enabled)
 *		    configure motor for stop or start
 *	    Else
 *		    If (head.enabled) and
 *            ((head.speed != head_prev.speed) || (head.forward != head_prev.forward))
 *		        update motor control parameters
 *          Endif
 *      Endif
 *
 *      Update head_state
 *
 *  Else if (head_state == HEAD_MOVING*)
 *      If head position has stopped, head_state = HEAD_DONE, update control structs
 *      Else update new head motor position
 *  Else
 *		Reset head_state = HEAD_IDLE
 *  Endif
 */

 	CORO_CONTEXT actuator_head
 	CORO_START	actuator_head
actuator_head_loop:
 	push	{r4, r5, r6, r7, r8, r9}

check_actuator_head_state:
	ldr		r4, =head_state
	ldrb	r0, [r4]
	cmp		r0, #HEAD_MOVING_DONE
	bne		check_head_idle

clear_head_state:
	mov		r0, #HEAD_IDLE
	strb	r0, [r4]						// Change state back to HEAD_IDLE
	// Fall through

check_head_idle:
	cmp		r0, #HEAD_IDLE
	beq		check_head_motor_statechange

check_head_moving:
	cmp		r0, #HEAD_MOVING_UP
	beq		head_moving_update
	cmp		r0, #HEAD_MOVING_DOWN
	beq		head_moving_update
	b		clear_head_state				// Unknown state, clear to HEAD_IDLE

head_moving_update:
	bl		has_head_stopped
	cmp		r0, #TRUE
	beq		head_motor_stop					// Head stopped
	b		actuator_head_done				// Wait for next activation to check again

check_head_motor_statechange:
	// Record staring position first as it will destroy r0-r3 used later
    ldr     r0, =head_prevpos
    bl      record_head_position            // Record starting position for head motor

	load_and_copy_motor_control_structs motor_control_struct_head motor_control_struct_prev_head
	mov		r2, #0
 	strb	r2, [r9, #motor_numsteps_offset]		// Override numsteps parameter

 	cmp		r0, r4
 	bne		head_motor_statechange

check_head_motor_update:
 	cmp		r0, #TRUE			// Head actuator enabled?
 	bne		actuator_head_done	// Stopped, so nothing else to check

compare_head_motor_speeds:
	cmp		r1, r5				// Compare speeds
	bne		head_motor_start	// Update motor config if different

compare_head_motor_direction:
	cmp		r3, r7
	bne		head_motor_start	// Update motor config if different

	b		actuator_head_done	// No match, so exit

head_motor_statechange:
 	cmp		r0, #TRUE			// Head actuator enabled?
 	bne		head_motor_stop

head_motor_start:
	// Check movement direction
	cmp		r3, #TRUE			// forward is DOWN, reverse is UP
	moveq	r5, #HEAD_MOVING_DOWN
	movne	r5, #HEAD_MOVING_UP
 	ldr		r4, =head_state
	strb	r5, [r4]

	// enable head motor
 	mov		r0, r3				// r0: forward, r1: speed
 	bl		start_head_tacho
	b		actuator_head_done				// Wait for next activation to check again

head_motor_stop:
	ldr		r4, =head_state
	mov		r0, #HEAD_MOVING_DONE
	strb	r0, [r4]						// Update state to HEAD_MOVING_DONE

	// The head actuator automatically stops the motor
	bl		stop_head_tacho					// Stop head motor

	ldr		r0, =motor_control_struct_prev_head
	bl		config_motor_stop				// Indicate motor has stopped in control struct
	ldr		r0, =motor_control_struct_head
	bl		config_motor_stop				// Indicate motor has stopped in control struct

	// Let Behaviors pick up HEAD_MOVING_DONE state update in next event loop

actuator_head_done:
 	pop	{r4, r5, r6, r7, r8, r9}
 	CORO_YIELD
 	b		actuator_head_loop
 	CORO_END

/*****************************************************************************/
/*
 * Coroutine for Limb Control (symmetrical for both limbs)
 *
 * Note: Since we're using push/pop in the Coroutine, there should not be any CORO_* macro calls
 *       between the push and the pop instructions
 *
 *  If (limb_state == LIMB_DONE)
 *      reset state to LIMB_IDLE
 *
 *  If ((limb_state == LIMB_IDLE) or (limb_state == LIMB_DONESYNC))
 *      Record Limb Motor Position
 *
 *	    If (limb.enabled != limb_prev.enabled)
 *			if start, start limb motor, increment num_running_motors, set limb_state = LIMB_MOVING
 *			if stop, set limb_state = LIMB_DONE 	// Check: The limb motor should be stopped when we get here
 *	    Else if (limb.enabled) and
 *            ((limb.speed != limb_prev.speed) || (limb.forward != limb_prev.forward)
 *				|| (limb.numsteps != limb_prev.numsteps))
 *		    update motor control parameters, set limb_state = LIMB_MOVING
 *      Else if (limb_state == LIMB_DONESYNC)
 *			start limb motor, increment num_running_motors, set limb_state = LIMB_MOVING
 *      Endif
 *
 *      Update limb_state
 *
 *  Else if (limb_state == LIMB_MOVING)
 *      If limb position reached
 *			Stop Limb Motor, decrement num_running_motors
 *			Adjust (Decrement) [num_steps | arc_count]
 *			if ([num_steps | arc_count] == 0)
 *				limb_state = LIMB_DONE, update control structs
 *			Else
 *				limb_state = LIMB_WAITSYNC
 *			Endif
 *		Endif
 *
 *  Else if (limb_state == LIMB_WAITSYNC)
 *			if (num_running_motors == 0), then limb_state = LIMB_DONESYNC
 *  Else
 *		Reset limb_state = LIMB_IDLE
 *  Endif
 *
 */

/** actuator_limb_left
 *
 * Coroutine for Limb Left Motor Control
 *
 */
  	CORO_CONTEXT actuator_limb_left
 	CORO_START	actuator_limb_left

actuator_limb_loop_left:
 	push	{r4, r5, r6, r7, r8, r9}
	ldr		r4, =limb_state_left
	ldr		r5, =limb_motor_struct_left

/*****************************************************************************/
check_actuator_limb_state_left:
	ldrb	r0, [r4]
	cmp		r0, #LIMB_DONE
	bne		check_limb_idle_left

clear_limb_state_left:
	mov		r0, #LIMB_IDLE
	strb	r0, [r4]						// Change state back to LIMB_IDLE
	// Fall through

check_limb_idle_left:
	cmp		r0, #LIMB_IDLE
	beq		check_limb_motor_statechange_left
	cmp		r0, #LIMB_DONESYNC
	beq		check_limb_motor_statechange_left

check_limb_moving_left:
	cmp		r0, #LIMB_MOVING
	beq		limb_moving_update_left

check_limb_waitsync_left:
	cmp		r0, #LIMB_WAITSYNC
	bne		clear_limb_state_left			// Unknown state, clear to LIMB_IDLE

	ldr		r0, =limb_state_left
	bl		check_limb_waitsync_done
	b		actuator_limb_done_left			// Wait till next event loop to restart motor (WAIT-YIELD semantics)

limb_moving_update_left:
	mov		r0, r5
	bl		has_limb_reached_targetpos
	cmp		r0, #TRUE
	bne		actuator_limb_done_left			// Limb has not completed movement, skip

limb_reached_targetpos_left:
    ldrb    r0, [r5, #limb_seqno_offset]    // Setup motor sequence number
    bl      stop_limb_tacho                 // Stop motor

update_remaining_limb_steps_arc_left:
	ldr		r0, =step_count_left
	ldr		r1, =arc_count_left
	bl		update_and_check_steps_done		// returns TRUE if movement done
	cmp		r0, #TRUE
	beq		limb_stop_left					// Movement done, so flag update

	mov		r0, #LIMB_WAITSYNC
	strb	r0, [r4]						// Update state
	b		actuator_limb_done_left			// Wait for other motors to complete movement

/*****************************************************************************/
check_limb_motor_statechange_left:
	load_and_copy_motor_control_structs		motor_control_struct_left motor_control_struct_prev_left
 	cmp		r0, r4
 	bne		limb_motor_statechange_left

check_limb_motor_update_left:
 	cmp		r0, #TRUE			// Limb actuator enabled?
 	bne		actuator_limb_done_left	// Stopped, so nothing else to check

compare_limb_motor_speeds_left:
	cmp		r1, r5				// Compare speeds
	bne		limb_start_left	// Update motor config if different

compare_limb_numsteps_left:
	cmp		r2, r6				// Compare num steps
	beq		compare_limb_motor_direction_left
	cmp		r2, #0				// Check if numsteps is non-zero
	bne		limb_start_left		// Update motor config if non-zero
	beq		limb_stop_left		// Otherwise stop movement	Note: Don't call stop_limb_tacho since it'll update num_running_motors

compare_limb_motor_direction_left:
	cmp		r3, r7
	bne		limb_start_left		// Update motor config if different

limb_motor_state_unchanged_left:
	ldr		r4, =limb_state_left
	ldrb	r0, [r4]
	cmp		r0, #LIMB_DONESYNC
	beq		limb_continue_left				// Should continue movement

	b		actuator_limb_done_left			// No change, skip

limb_motor_statechange_left:
 	cmp		r0, #TRUE						// Limb actuator enabled?
 	bne		limb_stop_left

/*****************************************************************************/
limb_start_left:
	// Setup Limb Tacho parameters with signed values using the inputs

    ldr     r5, =limb_motor_struct_left
    strb	r3, [r5, #limb_forward_offset]	// Record movement direction

	ldr		r6, =step_count_left
	ldr		r7, =arc_count_left
	strb	r2, [r6]						// Num Steps
	mov		r2, #NUM_ARCS_PER_STEP
	strb	r2, [r7]						// Arc Count

    ldr		r0, =countperrot
    ldr		r0, [r0]						// Retrieve unsigned countperrot value
    asr     r0, r0, #ROTATION_SCALING  		// setup scaled countperrot value

	cmp		r3, #TRUE
	beq		store_limb_parameters_left

reverse_limb_parameters_left:
	neg		r0, r0							// Calculate 2's complement of position delta in r0
	neg		r1, r1							// Calculate 2's complement of speed in r1

store_limb_parameters_left:
	str		r0, [r5, #sgn_limb_deltapos_offset]	// Record signed position delta
	str		r1, [r5, #sgn_limb_speed_offset]	// Record signed speed

store_initial_targetpos_left:
	// Setup Initial Limb Target Position
    ldrb    r0, [r5, #limb_seqno_offset]    // Retrieve sequence number
    add		r1, r5, #limb_targetpos_offset	// point to limb_targetpos variable in struct
    bl      get_tacho_position              // Record initial limb target tacho position

/*****************************************************************************/
limb_continue_left:
    ldr     r0, =limb_motor_struct_left
    bl      set_limb_targetpos_and_start_tacho   // Set new target and start motor

	ldr		r4, =limb_state_left
	mov		r0, #LIMB_MOVING
	strb	r0, [r4]						// Update state to LIMB_MOVING
	b		actuator_limb_done_left

limb_stop_left:
	ldr		r4, =limb_state_left
	mov		r0, #LIMB_DONE
	strb	r0, [r4]						// Update state to LIMB_DONE

	ldr		r0, =motor_control_struct_prev_left
	bl		config_motor_stop				// Indicate motor has stopped in control struct
	ldr		r0, =motor_control_struct_left
	bl		config_motor_stop				// Indicate motor has stopped in control struct

	// Let Behaviors pick up LIMB_DONE state update in next event loop

actuator_limb_done_left:
 	pop	{r4, r5, r6, r7, r8, r9}
 	CORO_YIELD
 	b		actuator_limb_loop_left
 	CORO_END


/** actuator_limb_right
 *
 * Coroutine for Limb Right Motor Control
 *
 */
  	CORO_CONTEXT actuator_limb_right
 	CORO_START	actuator_limb_right

actuator_limb_loop_right:
 	push	{r4, r5, r6, r7, r8, r9}
	ldr		r4, =limb_state_right
	ldr		r5, =limb_motor_struct_right

/*****************************************************************************/
check_actuator_limb_state_right:
	ldrb	r0, [r4]
	cmp		r0, #LIMB_DONE
	bne		check_limb_idle_right

clear_limb_state_right:
	mov		r0, #LIMB_IDLE
	strb	r0, [r4]						// Change state back to LIMB_IDLE
	// Fall through

check_limb_idle_right:
	cmp		r0, #LIMB_IDLE
	beq		check_limb_motor_statechange_right
	cmp		r0, #LIMB_DONESYNC
	beq		check_limb_motor_statechange_right

check_limb_moving_right:
	cmp		r0, #LIMB_MOVING
	beq		limb_moving_update_right

check_limb_waitsync_right:
	cmp		r0, #LIMB_WAITSYNC
	bne		clear_limb_state_right			// Unknown state, clear to LIMB_IDLE

	ldr		r0, =limb_state_right
	bl		check_limb_waitsync_done
	b		actuator_limb_done_right		// Wait till next event loop to restart motor (WAIT-YIELD semantics)

limb_moving_update_right:
	mov		r0, r5
	bl		has_limb_reached_targetpos
	cmp		r0, #TRUE
	bne		actuator_limb_done_right			// Limb has not completed movement, skip

limb_reached_targetpos_right:
    ldrb    r0, [r5, #limb_seqno_offset]    // Setup motor sequence number
    bl      stop_limb_tacho                 // Stop motor

update_remaining_limb_steps_arc_right:
	ldr		r0, =step_count_right
	ldr		r1, =arc_count_right
	bl		update_and_check_steps_done		// returns TRUE if movement done
	cmp		r0, #TRUE
	beq		limb_stop_right					// Movement done, so flag update

	mov		r0, #LIMB_WAITSYNC
	strb	r0, [r4]						// Update state
	b		actuator_limb_done_right			// Wait for other motors to complete movement

/*****************************************************************************/
check_limb_motor_statechange_right:
	load_and_copy_motor_control_structs		motor_control_struct_right motor_control_struct_prev_right
 	cmp		r0, r4
 	bne		limb_motor_statechange_right

check_limb_motor_update_right:
 	cmp		r0, #TRUE			// Limb actuator enabled?
 	bne		actuator_limb_done_right	// Stopped, so nothing else to check

compare_limb_motor_speeds_right:
	cmp		r1, r5				// Compare speeds
	bne		limb_start_right	// Update motor config if different

compare_limb_numsteps_right:
	cmp		r2, r6				// Compare num steps
	beq		compare_limb_motor_direction_right
	cmp		r2, #0				// Check if numsteps is non-zero
	bne		limb_start_right		// Update motor config if non-zero
	beq		limb_stop_right		// Otherwise stop movement	Note: Don't call stop_limb_tacho since it'll update num_running_motors

compare_limb_motor_direction_right:
	cmp		r3, r7
	bne		limb_start_right		// Update motor config if different

limb_motor_state_unchanged_right:
	ldr		r4, =limb_state_right
	ldrb	r0, [r4]
	cmp		r0, #LIMB_DONESYNC
	beq		limb_continue_right				// Should continue movement

	b		actuator_limb_done_right			// No change, skip

limb_motor_statechange_right:
 	cmp		r0, #TRUE						// Limb actuator enabled?
 	bne		limb_stop_right

/*****************************************************************************/
limb_start_right:
	// Setup Limb Tacho parameters with signed values using the inputs

    ldr     r5, =limb_motor_struct_right
    strb	r3, [r5, #limb_forward_offset]	// Record movement direction

	ldr		r6, =step_count_right
	ldr		r7, =arc_count_right
	strb	r2, [r6]						// Num Steps
	mov		r2, #NUM_ARCS_PER_STEP
	strb	r2, [r7]						// Arc Count

    ldr		r0, =countperrot
    ldr		r0, [r0]						// Retrieve unsigned countperrot value
    asr     r0, r0, #ROTATION_SCALING  		// setup scaled countperrot value

	cmp		r3, #TRUE
	beq		store_limb_parameters_right

reverse_limb_parameters_right:
	neg		r0, r0							// Calculate 2's complement of position delta in r0
	neg		r1, r1							// Calculate 2's complement of speed in r1

store_limb_parameters_right:
	str		r0, [r5, #sgn_limb_deltapos_offset]	// Record signed position delta
	str		r1, [r5, #sgn_limb_speed_offset]	// Record signed speed

store_initial_targetpos_right:
	// Setup Initial Limb Target Position
    ldrb    r0, [r5, #limb_seqno_offset]    // Retrieve sequence number
    add		r1, r5, #limb_targetpos_offset	// point to limb_targetpos variable in struct
    bl      get_tacho_position              // Record initial limb target tacho position

/*****************************************************************************/
limb_continue_right:
    ldr     r0, =limb_motor_struct_right
    bl      set_limb_targetpos_and_start_tacho   // Set new target and start motor

	ldr		r4, =limb_state_right
	mov		r0, #LIMB_MOVING
	strb	r0, [r4]						// Update state to LIMB_MOVING
	b		actuator_limb_done_right

limb_stop_right:
	ldr		r4, =limb_state_right
	mov		r0, #LIMB_DONE
	strb	r0, [r4]						// Update state to LIMB_DONE

	ldr		r0, =motor_control_struct_prev_right
	bl		config_motor_stop				// Indicate motor has stopped in control struct
	ldr		r0, =motor_control_struct_right
	bl		config_motor_stop				// Indicate motor has stopped in control struct

	// Let Behaviors pick up LIMB_DONE state update in next event loop

actuator_limb_done_right:
 	pop	{r4, r5, r6, r7, r8, r9}
 	CORO_YIELD
 	b		actuator_limb_loop_right
 	CORO_END

/*****************************************************************************/
/** sensor_color
 *
 * Coroutine for Color Sensor Inputs
 *
 */
    // Coroutine Variables for sensor_color
    .align
    CORO_LOCAL	 color_index, byte, 0

 	CORO_CONTEXT sensor_color
 	CORO_START	sensor_color
color_loop:
 	push	{r4}						// preserve temporary variable registers
 	mov		r4, #NUM_COLOR_READINGS

next_color_reading:
  	sub		r4, r4, #1					// point to current index

	record_systick color_last_systick	// record systick for current color sensor reading
 	mov		r0, #0						// value index
 	ldr		r1, =seqno_color
 	ldrb	r1, [r1]
 	ldr		r2, =color_intensity_array
	add		r2, r2, r4, lsl #2			// setup address pointer for input value (index for 32-bit integer)
 	bl		get_sensor_value

	cmp		r4, #0						// have we collected all of them?
 	beq		done_num_readings

wait_next_reading:

#ifdef USE_USLEEP
	wait_3ms
#else
	ldr		r1, =color_last_systick
	ldr		r2, =COLOR_READ_INTERVAL
	ldr		r3, [r1]						// Retrieve Color Sensor last reading systick
	add		r0, r3, r2						// New Color Sensor read time
	bl		has_timer_expired
 	cmp		r0, #TRUE
 	bne		wait_next_reading
#endif
 	// Interval Elapsed
 	b		next_color_reading

done_num_readings:
	ldr		r0, =color_intensity_array
	mov		r1, #NUM_COLOR_READINGS
	ldr		r2, =color_intensity_min
	ldr		r3, =color_intensity_max
	bl		min_max_u32					// perform min-max calculation

 	pop		{r4}						// restore temporary variable registers
	CORO_YIELD
	b		color_loop

 	CORO_END

/*****************************************************************************/
/** sensor_touch
 *
 * Coroutine for Touch Sensor Inputs
 *
 */
    // Coroutine Variables for sensor_touch
 	CORO_CONTEXT sensor_touch
 	CORO_START	sensor_touch
 touch_loop:
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
	CORO_YIELD
	b		touch_loop

 	CORO_END

/*****************************************************************************/


/*****************************************************************************/
/* Behavior Routines
/*****************************************************************************/

    .code 32
    .text
    .align

/*****************************************************************************/
/**
 *    Escape Behavior (Highest Priority)
 *
 *    This behavior has two parts: move the head up, and escape by moving
 *     the limbs forward X steps.
 *
 *    The status of the head movement and escape status are tracked using state variable.
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
	BEHAVIOR_PROLOGUE	escape
escape_start:

	DISPLAY_ROBOT_STATE behavior_escapestr

	ldr		r2, =head_state					// Setup head actuator state pointer
	ldr		r3, =headpos_state				// Setup head position state pointer

check_headpos_state:
	ldrb	r0, [r3]						// Get current Head Position State
	cmp		r0, #HEADPOS_UP					// Are we in desired state?
	beq		check_escape_state				// yes, so skip checking
check_head_done:
	ldrb	r0, [r2]						// Get current head movement state
	cmp		r0, #HEAD_MOVING_DONE			// Are we currently moving the head?
	beq		update_headpos_state

check_head_moving_up:
	cmp		r0, #HEAD_MOVING_UP				// Have we started moving the head up?
	beq		check_escape_state				// yes, so skip update

config_head_movement:
	// Setup Head Controller actions
	ldr		r0, =motor_control_struct_head
	mov		r1, #HEAD_MAX_SPEED
	mov		r2, #0							// Num steps is not used by Head Controller
	bl		config_motor_reverse			// Start Head Motor movement
	b		check_escape_state

update_headpos_state:
	mov		r0, #HEADPOS_UP
	strb	r0, [r3]						// Flag Head Movement Done

check_escape_state:
	ldr		r3, =escape_state				// Setup state variable pointer
	ldrb	r0, [r3]						// Get current Escape State
	cmp		r0, #ESCAPE_DONE				// Are we done escaping?
	beq		check_behavior_escape_done		// yes, so check if we're all done with the behavior

check_escape_escaping:
	cmp		r0, #ESCAPE_ESCAPING			// Are we still escaping?
	beq		check_escape_done

config_escape:
	mov		r0, #ESCAPE_ESCAPING
	strb	r0, [r3]						// Update Escape State variable

	// Move X steps forward
	bl		random							// Generate a random value in r0
	and		r2, r0, #0x3					// Keep last 2 bits as step count (0-3)
	add		r2, r2, #1						// make sure there is at least one step (1-4)
	mov		r0, #MOVE_FORWARD
	ldr		r1, =TACHO_MAX_SPEED
	bl		movement_selector				// Setup movement
	b		exit_behavior_escape			// Wait for next iteration of coroutine to check again

check_escape_done:
	bl		is_escape_movement_done
	cmp		r0, #TRUE						// Are we done with escape movement?
	bne		exit_behavior_escape			// No, so wait for next iteration of coroutine to check again

update_escape_state:
	ldr		r3, =escape_state				// Setup state variable pointer
	mov		r0, #ESCAPE_DONE
	strb	r0, [r3]						// Update Escape State variable

check_behavior_escape_done:
	ldr		r3, =headpos_state					// Setup state variable pointer
	ldrb	r0, [r3]						// Get current Head State
	cmp		r0, #HEADPOS_UP					// Are we in desired state?
	bne		exit_behavior_escape			// No, so wait for next iteration of coroutine to check again

	ldr		r3, =escape_state				// Setup state variable pointer
	ldrb	r0, [r3]						// Get current Escape State
	cmp		r0, #ESCAPE_DONE				// Are we done escaping?
	bne		exit_behavior_escape			// No, so wait for next iteration of coroutine to check again

update_behavior_escape_done:
	// Reset Escape State
	mov		r0, #ESCAPE_IDLE
	strb	r0, [r3]						// Update Escape State variable

  	// Clear sting_activated state variable
 	ldr		r1, =sting_activated
 	mov		r0, #FALSE
 	strb	r0, [r1]

exit_behavior_escape:
	BEHAVIOR_EPILOGUE escape

trigger_escape:
	ldr		r1, =sting_activated
	ldrb	r0, [r1]
	cmp		r0, #FALSE
	movne	r0, #TRUE						// Touch Activated, so flag TRUE
	mov		pc, lr

/*****************************************************************************/
/**
 *    Follow Path Behavior
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
	BEHAVIOR_PROLOGUE	followpath

	DISPLAY_ROBOT_STATE	behavior_followpathstr

	BEHAVIOR_EPILOGUE followpath

/** trigger_followpath
 *
 *    Activated when Sting is inactive and Head Position is Down
 *
 **/
trigger_followpath:
#if 0									// Not Activated yet

	ldr		r1, =sting_activated
	ldrb	r0, [r1]
	cmp		r0, #FALSE
	bne		disable_followpath

check_followpath_head_position:
	// Check Head Position state
	ldr		r1, =headpos_state				// Setup head position state pointer
	ldrb	r0, [r1]
	cmp		r0, #HEADPOS_DOWN
	beq		enable_followpath

disable_followpath:
	mov		r0, #FALSE
	mov		pc, lr

enable_followpath:
	mov		r0, #TRUE
	mov		pc, lr
#else
	mov		r0, #FALSE
	mov		pc, lr
#endif

/*****************************************************************************/
/**
 *    Lower Head Behavior
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
	BEHAVIOR_PROLOGUE	lower_head

	DISPLAY_ROBOT_STATE	behavior_lowerheadstr

	ldr		r2, =head_state					// Setup head actuator state pointer
	ldr		r3, =headpos_state				// Setup head position state pointer

check_lower_head_done:
	ldrb	r0, [r2]						// Get current head movement state
	cmp		r0, #HEAD_MOVING_DONE			// Are we currently moving the head?
	beq		update_lower_headpos_state

check_head_moving_down:
	cmp		r0, #HEAD_MOVING_DOWN			// Have we started moving the head down?
	beq		exit_behavior_lower_head		// yes, so skip update

config_lower_head_movement:
	// Setup Head Controller actions
	ldr		r0, =motor_control_struct_head
	mov		r1, #HEAD_MAX_SPEED
	mov		r2, #0							// Num steps is not used by Head Controller
	bl		config_motor_forward			// Start Head Motor movement
	b		exit_behavior_lower_head

update_lower_headpos_state:
	mov		r0, #HEADPOS_DOWN
	strb	r0, [r3]						// Flag Head Movement Done

exit_behavior_lower_head:
	BEHAVIOR_EPILOGUE lower_head

/** trigger_lower_head
 *
 *    Enable Lower Head if Head Position is Up or Unknown
 *
 **/
trigger_lower_head:
	// Check Head Position state
	ldr		r1, =headpos_state				// Setup head position state pointer
	ldrb	r0, [r1]
	cmp		r0, #HEADPOS_UNKNOWN
	beq		enable_lower_head
	cmp		r0, #HEADPOS_UP
	beq		enable_lower_head

disable_lower_head:
	mov		r0, #FALSE
	mov		pc, lr

enable_lower_head:
	mov		r0, #TRUE
	mov		pc, lr

/*****************************************************************************/
/**
 *    Idle Behavior (Lowest Priority)
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 **/
	BEHAVIOR_PROLOGUE	idle

	DISPLAY_ROBOT_STATE	behavior_idlestr

	ldr		r0, =motor_control_struct_head
	bl		config_motor_stop

#if 1
	// Use movement routine to setup actuator controller
	mov		r0, #MOVE_STOP
	bl		movement_selector				// Setup movement
#else
	// Configure each motor separately
	ldr		r0, =motor_control_struct_left
	bl		config_motor_stop
	ldr		r0, =motor_control_struct_right
	bl		config_motor_stop
#endif
	BEHAVIOR_EPILOGUE idle

/** trigger_idle
 *
 *    Always triggered
 *
 **/
trigger_idle:
	mov		r0, #TRUE
	mov		pc, lr

/*****************************************************************************/
/* Robot Configuration and Utility Routines
/*****************************************************************************/

    .code 32
    .text
    .align

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

	// Setup limb motor struct
	ldr		r4, =limb_motor_struct_left
	ldr		r5, =limb_motor_struct_right

	ldr		r0, =seqno_left                 // read left motor seqno U8 from memory into r0
	ldrb	r0, [r0]
	strb	r0, [r4, #limb_seqno_offset]	// Configure the limb motor struct
	ldr		r1, =seqno_right                // read right motor seqno U8 from memory into r0
	ldrb	r1, [r1]
	strb	r1, [r5, #limb_seqno_offset]	// Configure the limb motor struct

    // Limb motor configuration
    ldr     r4, =countperrot                // Pointer to variable
    ldr     r5, =motors_vec                 // setup motor vector

    // Retrieve countperrot value from left motor
	// left motor seqno is already in r0
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

#ifdef USE_USLEEP
	mov		r0, r2							// Setup usleep duration
	bl		usleep							// Call usleep()
	b		exit_sleep

#else
systick_busywait:
	bl		tick_systick					// returns current systick in r0
	ldr		r1, =loop_systick
	ldr		r3, [r1]						// get current loop starting systick
	subs	r2, r0, r3						// check (r2 = (current systick - next loop_systick)) < 0
	blt		systick_busywait				// Busy Wait for loop expiry
	b		exit_sleep

#endif

no_sleep:
	str		r0, [r1]						// Store current systick as the start of the next event loop
	ldr		r1, =loop_exceeded
	ldr		r0, [r1]
	add		r0, r0, #1
	str		r0, [r1]						// Update loop_exceeded count

#ifdef DEBUG_LOOPCOUNT_EXCEEDED
	DISPLAY_DEBUG_INT exceeded_loopcnt_str r0
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

	// Setup Escape State to ESCAPE_IDLE
	mov		r0, #ESCAPE_IDLE
	ldr		r1, =escape_state
	strb	r0, [r1]

	// Configure Head Position state
	ldr		r1, =headpos_state				// Setup head position state pointer
	mov		r0, #HEADPOS_UNKNOWN
	strb	r0, [r1]						// Update current Head Position State

	// Setup Head State to HEAD_IDLE
	mov		r0, #HEAD_IDLE
	ldr		r1, =head_state
	strb	r0, [r1]

	// Setup Limb States to LIMB_IDLE
	mov		r0, #LIMB_IDLE
	ldr		r1, =limb_state_left
	strb	r0, [r1]
	ldr		r1, =limb_state_right
	strb	r0, [r1]

	// Setup Limb Actuator Movement Struct
	mov		r0, #0
	ldr		r1, =limb_actuator_struct
	mov		r2, #limb_actuator_struct_size

limb_actuator_struct_init_loop:
	sub		r2, r2, #1
	strb	r0, [r1, r2]
	teq		r2, #0
	bne		limb_actuator_struct_init_loop

	// Setup Robot State to ROBOT_IDLE
	mov		r0, #ROBOT_IDLE
	ldr		r1, =robot_state
	strb	r0, [r1]

    pop     {pc}


/** check_exit
 *
 *   Check status of button to see if it is being pressed.
 *
 *   Note: ev3_read_keys check the instantaneous keypress state.
 *         It does not remember / buffer previous key presses
 *
 *   // WARNING: This routine can hang the program if called from inside a coroutine
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

	// Initialize Coroutine Contexts
	CORO_CONTEXT_INIT sensor_color			// reset color input gathering
	CORO_CONTEXT_INIT sensor_touch			// reset touch input gathering

	CORO_CONTEXT_INIT actuator_head			// Reset head actuator context
	CORO_CONTEXT_INIT actuator_limb_left	// Reset limbs actuator context
	CORO_CONTEXT_INIT actuator_limb_right	// Reset limbs actuator context

	// Suppress all behaviors on first pass to reset behaviors
	set_bhvr_suppress	TRUE

	// Configure loop_systick before starting event loop
	record_systick loop_systick

event_loop:

	// Check Exit Keypress
	bl		check_exit
	cmp		r0, #TRUE
	beq		robot_cleanup					// Exit detected

/*****************************************************************************/
	// Input Controller (Update sensor and keypress inputs)
input_controller:
	CORO_CALL	sensor_color
	CORO_CALL	sensor_touch

/*****************************************************************************/
	// Behavior Dispatcher
	//   Execute behaviors based on priority as long as they are not suppressed
	//   Else, reset the behavior
	//
behavior_dispatcher:
	CALL_BEHAVIOR escape
	CALL_BEHAVIOR followpath
	CALL_BEHAVIOR lower_head
	CALL_BEHAVIOR idle
	set_bhvr_suppress	FALSE				// Clear bhvr_suppress flag

/*****************************************************************************/
	// Actuator Controller (Configure actuator outputs)
actuator_controller:
	CORO_CALL	actuator_head
	CORO_CALL	actuator_limb_left
	CORO_CALL	actuator_limb_right

	// Reduce wait-yield duration by 1 event loop by checking outside the actuator coroutines
check_waitsync_left:
	ldr		r0, =limb_state_left
	ldrb	r1, [r0]
	cmp		r1, #LIMB_WAITSYNC
	bne		check_waitsync_right
	bl		check_limb_waitsync_done

check_waitsync_right:
	ldr		r0, =limb_state_right
	ldrb	r1, [r0]
	cmp		r1, #LIMB_WAITSYNC
	bne		done_check_waitsync
	bl		check_limb_waitsync_done

done_check_waitsync:
/*****************************************************************************/

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
