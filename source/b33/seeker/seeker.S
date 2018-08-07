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
#include "ev3dev-arm-bbr.h"
#include "../b33.h"

/* Standard C Library routines */
	.extern	random									// <stdlib.h>
	.extern srandom									// <stdlib.h>
	.extern getpid									// <unistd.h>

    // Number of stinger activations
    .equiv  NUM_STINGS, 4
    // Number of steps to take per activation
    .equiv  NUM_STEPS, 3
    // Number of LEGO MINDSTORM Large Servo Motors
    .equiv  NUM_MOTORS, 2
    // Scaling factor in no. of right bitshifts for countperrot (ASR 2 == div. 4 [90 deg])
    .equiv  ROTATION_SCALING, 2
    // Number of LEGO MINDSTORM Sensors
    .equiv  NUM_SENSORS, 2
	// Size of display output buffer
	.equiv		DISPLAYBUF_SIZE, 256

    .data
    .align

titlestr:       .asciz  "Seeker Robot"
waitltachostr:  .asciz  "Waiting (Left Tacho Port B)  "
waitrtachostr:  .asciz  "Waiting (Right Tacho Port C) "
waitheadstr:    .asciz  "Waiting (Head Motor any port)"

foundmotor0str:	.asciz  "Tacho: L("
foundmotor1str:	.asciz  "), R("
foundmotor2str: .asciz  "), H("
foundmotorNstr: .asciz  ")  "

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

#if 1
waitingstr:     .asciz      "Waiting for input..."
donestr:        .asciz      "Seeker done!        "
#endif

// Need to align the following data, otherwise the string termination is not guaranteed
    .align
countperrot:    .word   0                   // Tacho count per rotation (360 deg)
                                            // Assume identical for both motors
touch_val:		.word	0					// Touch sensor input buffer

/* Coroutine synchronization variable */
num_running_motors: .word    0

// Vector of actuator seqnos needed by multi_set_tacho_XXX()

/* Vector of all actuator motors (including head and limb motors) */
actuators_vec:
seqno_head:     .byte   0
/* Vector of all limb motors */
motors_vec:
seqno_right:    .byte   0                   // Sequence number for right motor
seqno_left:     .byte   0                   // Sequence number for left motor
endmotors:      .byte   DESC_LIMIT          // Vector Terminator

    .equiv      motors_vec_len, . - motors_vec

seqno_touch:    .byte   0
seqno_color:    .byte   0
keypress:		.byte	EV3_KEY__NONE_


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
    bl      get_tacho_position              // Take current position reading for motor_\side

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
    mov     r3, #TACHO_MAX_SPEED            // Target speed of the motor

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

    .code 32
    .text
    .align
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
/* Coroutine Instantiation
/*****************************************************************************/
    DEFINE_COROUTINE_MOTOR left
    DEFINE_COROUTINE_MOTOR right

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

/*****************************************************************************/
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

/*****************************************************************************/
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
    cmp     r0, #2
    bge     find_l_motor
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

/** init_robot
 *
 *   Initialize Robot Sensors and Actuators
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 **/
init_robot:
    push    {lr}
    bl      init_sensors
    bl      init_motors
    bl      setup_motors
    pop     {pc}

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

/*****************************************************************************/

/** main
 *
 *   Main application routine
 *
 * Variables:
 *   R4: Sequence No of Touch Sensor
 *   R5: Address of touch_val
 *   R6: Number of steps
 *   R7: No of motors for coroutine dispatcher
 *   R8: Number of stinger activations
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

    bl		getpid							// Retrieve the PID of the process, as srandom seed
	bl		srandom							// Initialize random number generator

    ldr		r4, =seqno_touch
    ldrb	r4, [r4]						// Retrieve touch sensor sequence number

    ldr		r5, =touch_val					// Pointer to touch_val

    mov		r8, #NUM_STINGS					// Number of activations

#if 1
    mov		r9, #0							// Test movement using movement index in r9
#endif

activation_loop:
    ldr     r0, =waitingstr
    mov		r1, #7							// Row 7
    bl      prog_contentX

    mov     r0, r8                          // Display sting counter
    mov     r1, #2                          // Right aligned 2 digit counter
    bl      prog_display_integer_aligned

wait_stinger:
	WAIT_10MS								// Delay 10 ms

    mov     r0, #0
    mov		r1, r4							// touch sensor sequence number
    mov		r2, r5							// pointer to touch_val
    bl		get_sensor_value
    cmp     r0, #0
    beq		wait_stinger					// No value read, keep waiting

	ldr		r0, [r5]						// Retrieve touch value
	cmp		r0, #0
	beq		wait_stinger					// Value is 0 (no touch), keep waiting

    mov     r6, #NUM_STEPS                  // Setup step count

#if 0
	bl		random							// Generate a random value in R0
	and		r0, r0, #0x3					// Keep last 2 bits
#else
    mov     r0, r9							// Retrieve movement index
#endif

movement_selector:
	// Case random() r0[1:0] of:
	//   0: straight ahead (both motor forward)
	//   1: straight back (both motor reverse)
	//   2: circle to the left (right motor forward)
	//   3: circle to the right (left motor forward)
case_0_check:
    cmp		r0, #0
    bne		case_1_check
	// Enable Left Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_left
    // Enable Right Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_right
    mov     r10, #NUM_MOTORS
	b		step

case_1_check:
    cmp		r0, #1
    bne		case_2_check
	// Enable Left Motor Reverse
    mov		r0, #TRUE
    mov		r1, #FALSE
    bl		motor_config_left
    // Enable Right Motor Reverse
    mov		r0, #TRUE
    mov		r1, #FALSE
    bl		motor_config_right
    mov     r10, #NUM_MOTORS
	b		step

case_2_check:
    cmp		r0, #2
    bne		case_3_check
	// Disable Left Motor
    mov		r0, #FALSE
    mov		r1, #FALSE
    bl		motor_config_left
    // Enable Right Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_right
    mov     r10, #1
	b		step

case_3_check:
	// Enable Left Motor Forward
    mov		r0, #TRUE
    mov		r1, #TRUE
    bl		motor_config_left
    // Disable Right Motor
    mov		r0, #FALSE
    mov		r1, #FALSE
    bl		motor_config_right
    mov     r10, #1

step:

    // Reset Coroutines for coroutine_dispatcher
    CORO_CONTEXT_INIT motor_left
    CORO_CONTEXT_INIT motor_right

    // initialize num_running_motors synchronization variable
    ldr     r1, =num_running_motors
    mov     r0, #0
    str     r0, [r1]

coroutine_dispatcher:
    // Setup number of motors for coroutine dispatcher
    mov         r7, #NUM_MOTORS

    ldr         r0, =SLEEP_DURATION_10MS
    bl          usleep                      // Check every 10 ms
    CORO_CALL   motor_left                  // Complete one 360 deg rotation
    cmp         r0, #CO_END
    subeq       r7, r7, #1
    CORO_CALL   motor_right                 // Complete one 360 deg rotation
    cmp         r0, #CO_END
    subeq       r7, r7, #1
    cmp         r7, #0
    bgt         coroutine_dispatcher

    subs    r6, r6, #1                      // Continue until movement done
    bgt     step

	/* This is only needed if we're running in the debugger on the remote console.
	   Brickman will automatically exit if pressed-and-held for 2 seconds */
	// Check if Exit button pressed
	bl		check_exit
	cmp		r0, #TRUE
	beq		robot_cleanup

check_stings:
    subs    r8, r8, #1
#if 1
    add     r9, r9, #1						// Update movement index
    and		r9, r9, #0x3					// index modulo 4
#endif
    bne     activation_loop					// Continue until sting activations done

robot_cleanup:
    ldr     r0, =donestr
    mov		r1, #7							// Row 7
    bl      prog_contentX

    bl      stop_and_release_motors

/************************* End Customization Here ****************************/

exit_main:
    bl      prog_exit
    pop     {pc}

    .end
