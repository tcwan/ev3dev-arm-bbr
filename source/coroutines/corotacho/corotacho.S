/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  corotacho.S
 *  \brief  ARM-based Dual Tacho Motor (LEGO Large Servo Motor) example using coroutines.
 *          Two Large Servo Motor must be attached to ports OUTPUT_B and OUTPUT_C.
 *          OUTPUT_B is the Left Motor while OUTPUT_C is the Right Motor.
 *          The motors will rotate for NUM_LOOPS rotations, but each motor will not start
 *          the next rotation until both motors have completed their respective rotation 
 *          for the loop.
 *
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "ev3_both.h"
#include "ev3_port.h"
#include "ev3_tacho.h"
#include "ev3dev-arm-bbr.h"

#define L_MOTOR_PORT      OUTPUT_B
#define L_MOTOR_EXT_PORT  EXT_PORT__NONE_
#define R_MOTOR_PORT      OUTPUT_C
#define R_MOTOR_EXT_PORT  EXT_PORT__NONE_

#define TACHO_MOTOR_TYPE    LEGO_EV3_L_MOTOR        // Use LEGO_EV3_M_MOTOR for Medium Servo Motor
#define TACHO_MAX_SPEED     200                     // Be careful not to set too large a number
#define TACHO_RAMPTIME_MS   100                     // 100 ms to ramp up/down to speed
#define TACHO_STOP_MODE     TACHO_BRAKE             // TACHO_COAST, TACHO_BRAKE, TACHO_HOLD
#define TACHO_RUN_MODE      TACHO_RUN_FOREVER       // TACHO_RUN_TO_REL_POS, TACHO_RUN_FOREVER

    .equiv  NUM_LOOPS, 10
    // Scaling factor in no. of right bitshifts for countperrot (ASR 2 == div. 4 [90 deg])
    .equiv  ROTATION_SCALING, 2                     

    .data
    .align

printstr:       .asciz "Coroutine Tacho Motor Test\n(LEGO Large Servo Motors)\n"
waitltachostr:  .asciz      "Waiting (Left Tacho Port B) \n"
waitrtachostr:  .asciz      "Waiting (Right Tacho Port C)\n"
foundlefttachostr:  .asciz  "Tacho: Left ("
foundrighttachostr: .asciz  "), Right ("
foundtachoendstr:   .asciz  ")   "
loopstr:        .asciz "Remaining loops: "

// Need to align the following data, otherwise the string termination is not guaranteed
    .align
countperrot:    .word   0                   // Tacho count per rotation (360 deg)
                                            // Assume identical for both motors

motors_vec:                     // Vector of motor seqnos needed by multi_set_tacho_XXX()
rightseqno:     .byte   0                   // Sequence number for right motor
leftseqno:      .byte   0                   // Sequence number for left motor
endmotors:      .byte   DESC_LIMIT          // Vector Terminator

    .equiv      motors_vec_len, . - motors_vec

/* Coroutine synchronization variable */
num_running_motors: .word    0

/* Coroutine related variables */

    .align 2

    CORO_LOCAL      left_count, word, 0
    CORO_LOCAL      right_count, word, 0
    CORO_LOCAL      left_tacho_currpos, word, 0
    CORO_LOCAL      left_tacho_targetpos, word, 0
    CORO_LOCAL      right_tacho_currpos, word, 0
    CORO_LOCAL      right_tacho_targetpos, word, 0

    CORO_CONTEXT    left_tacho
    CORO_CONTEXT    right_tacho

    .code 32
    .text
    .align

wait_500ms:
    push    {lr}
    ldr     r0, =SLEEP_DURATION_500MS
    bl      usleep
    pop     {pc}

/**
 *   Initialize Tacho Subsystem
 *
 *   Modifies (and returns):
 *        R4: left seqno value
 *        R5: right seqno value
 *
 *   Note: init_tacho does not conform to AAPCS as it modifies R4 and R5
 **/
init_tacho:
    push    {lr}
detect_tacho:
    bl      ev3_tacho_init                  // Returns number of motors detected
    cmp     r0, #2
    bge     find_l_motor
    ldr     r0, =SLEEP_DURATION_1SEC
    bl      usleep
    b       detect_tacho                    // Loop until tacho motors detected

find_l_motor:
    ldr     r0, =waitltachostr
    bl      prog_content1
    mov     r0, #TACHO_MOTOR_TYPE
    mov     r1, #L_MOTOR_PORT
    mov     r2, #L_MOTOR_EXT_PORT
    ldr     r3, =leftseqno
    // Search for TACHO_MOTOR_TYPE attached to L_MOTOR_PORT, return found flag
    bl      dvcs_search_tacho_type_for_port 
    cmp     r0, #FALSE
    bne     find_r_motor
    bl      ev3_tacho_init                  // Not found, reinitialize ev3_tacho desc
    bl      wait_500ms
    b       find_l_motor                    // Delay 500 ms, try again

find_r_motor:
    ldr     r0, =waitrtachostr
    bl      prog_content1
    mov     r0, #TACHO_MOTOR_TYPE
    mov     r1, #R_MOTOR_PORT
    mov     r2, #R_MOTOR_EXT_PORT
    ldr     r3, =rightseqno
    // Search for TACHO_MOTOR_TYPE attached to R_MOTOR_PORT, return found flag
    bl      dvcs_search_tacho_type_for_port 
    cmp     r0, #FALSE
    bne     found_motors
    bl      ev3_tacho_init                  // Not found, reinitialize ev3_tacho desc
    bl      wait_500ms
    b       find_r_motor                    // Delay 500 ms, try again

found_motors:
    ldr     r0, =foundlefttachostr
    bl      prog_content1

    ldr     r4, =leftseqno
    ldrb    r4, [r4]                        // read seqno U8 from memory into r4
    mov     r0, r4                          // setup left motor sequence number
    bl      prog_display_integer

    ldr     r0, =foundrighttachostr
    bl      prog_display_string

    ldr     r5, =rightseqno
    ldrb    r5, [r5]                        // read seqno U8 from memory into r5
    mov     r0, r5                          // setup right motor sequence number
    bl      prog_display_integer

    ldr     r0, =foundtachoendstr
    bl      prog_display_string
    pop     {pc}

stop_and_release_tachos:
    push    {lr}
    ldr     r0, =motors_vec                 // setup motor vector
    mov     r1, #TACHO_STOP             // set run mode
    bl      multi_set_tacho_command_inx
    ldr     r0, =motors_vec                 // setup motor vector
    mov     r1, #TACHO_COAST                // release motor
    bl      multi_set_tacho_stop_action_inx
    pop     {pc}

has_left_tacho_reached_target:
    push    {r4, lr}
    ldr     r0, =leftseqno
    ldrb    r0, [r0]                        // Retrieve actual sequence number value
    ldr     r4, =left_tacho_currpos
    mov     r1, r4                          // Setup parameter
    bl      get_tacho_position              // Take current position reading

    ldr     r0, [r4]                        // Retrieve current position
    ldr     r1, =left_tacho_targetpos
    ldr     r1, [r1]                        // Target left Position
    cmp     r0, r1                          // (currposition - targetposition) < 0?
    movge   r0, #TRUE
    movlt   r0, #FALSE
    pop     {r4, pc}

has_right_tacho_reached_target:
    push    {r4, lr}
    ldr     r0, =rightseqno
    ldrb    r0, [r0]                        // Retrieve actual sequence number value
    ldr     r4, =right_tacho_currpos
    mov     r1, r4                          // Setup parameter
    bl      get_tacho_position              // Take current position reading

    ldr     r0, [r4]                        // Retrieve current position
    ldr     r1, =right_tacho_targetpos
    ldr     r1, [r1]                        // Target right Position
    cmp     r0, r1                          // (currposition - targetposition) < 0?
    movge   r0, #TRUE
    movlt   r0, #FALSE
    pop     {r4, pc}

has_no_running_motors:
    ldr     r0, =num_running_motors
    ldr     r0, [r0]
    teq     r0, #0
    moveq   r0, #TRUE
    movne   r0, #FALSE
    mov     pc, lr                          // returns TRUE if num_running_motors is zero

/** advance_tacho_target_position
 *
 * Parameters:
 *    r0: pointer to tacho target position
 */
advance_tacho_target_position:
    ldr     r1, [r0]                        // old target position
    ldr     r2, =countperrot
    ldr     r2, [r2]                        // retrieve countperrot
    // new target position = scaled countperrot + old target position
    add     r1, r1, r2, asr #ROTATION_SCALING   
    str     r1, [r0]                        // store new target position
    bx      lr

/** start_tacho
 *
 * Parameters:
 *    r0: motor sequence number
 */
start_tacho:
    // start motor
    push    {lr}
    mov     r1, #TACHO_RUN_MODE             // configure run mode
    bl      set_tacho_command_inx
    ldr     r1, =num_running_motors
    ldr     r0, [r1]
    add     r0, r0, #1
    str     r0, [r1]                        // increment num_running_motors
    pop     {pc}

/** stop_tacho
 *
 * Parameters:
 *    r0: motor sequence number
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

/**
 * Coroutine: left_tacho
 */
    CORO_START  left_tacho

    ldr     r1, =left_count
    // determine no. of times to move motor using scaled rotation angle (subset of 360 deg)
    mov     r0, #(1 << ROTATION_SCALING)    
    str     r0, [r1]

left_advance:
    ldr     r0, =left_tacho_targetpos
    bl      advance_tacho_target_position   // Set new target

    ldr     r0, =leftseqno
    ldrb    r0, [r0]                        // Setup motor sequence number
    bl      start_tacho                     // Start motor

    CORO_WAIT   has_left_tacho_reached_target

    ldr     r0, =leftseqno
    ldrb    r0, [r0]                        // Setup motor sequence number
    bl      stop_tacho                      // Don't let one motor get ahead of the other

    CORO_WAIT   has_no_running_motors       // Don't let one motor get ahead of the other

    ldr     r1, =left_count
    ldr     r0, [r1]
    subs    r0, r0, #1
    str     r0, [r1]
    bne     left_advance                    // Not done with 360 deg rotation yet
    CORO_END

/**
 * Coroutine: right_tacho
 */
    CORO_START  right_tacho

    ldr     r1, =right_count
    // determine no. of times to move motor using scaled rotation angle (subset of 360 deg)
    mov     r0, #(1 << ROTATION_SCALING)    
    str     r0, [r1]

right_advance:
    ldr     r0, =right_tacho_targetpos
    bl      advance_tacho_target_position   // Set new target

    ldr     r0, =rightseqno
    ldrb    r0, [r0]                        // Setup motor sequence number
    bl      start_tacho                     // Start motor

    CORO_WAIT   has_right_tacho_reached_target

    ldr     r0, =rightseqno
    ldrb    r0, [r0]                        // Setup motor sequence number
    bl      stop_tacho                      // Don't let one motor get ahead of the other

    CORO_WAIT   has_no_running_motors       // Don't let one motor get ahead of the other

    ldr     r1, =right_count
    ldr     r0, [r1]
    subs    r0, r0, #1
    str     r0, [r1]
    bne     right_advance                   // Not done with 360 deg rotation yet
    CORO_END


/**
 *   Main application routine
 *
 *   Variables:
 *        R4: left seqno value
 *        R5: right seqno value
 *        R6: Loop Counter value
 *        R7: No of motors for coroutine dispatcher
 *        R8: countperrot value
 **/
    .global main
main:
    push    {lr}
    bl      prog_init
    ldr     r0, =printstr
    bl      prog_title
    bl      wait_500ms

    bl      init_tacho                      // r4, r5 setup with left, right tacho seqnos

tacho_setup:
    ldr     r8, =countperrot                // Pointer to variable

    mov     r0, r4                          // setup motor sequence number
    mov     r1, r8
    bl      get_tacho_count_per_rot         // retrieve count per rotation
    ldr     r8, [r8]                        // Load countperrot value

    // Setup target position for motor rotation (one full rotation)
    ldr     r0, =motors_vec                 // setup motor vector
    mov     r1, r8, asr #ROTATION_SCALING   // setup scaled countperrot value
    bl      multi_set_tacho_position_sp     // Setup target position

    // Setup Ramp/Up down duration (ms)
    ldr     r0, =motors_vec                 // setup motor vector
    ldr     r1, =TACHO_RAMPTIME_MS          // Ramp up duration (ms)
    bl      multi_set_tacho_ramp_up_sp

    ldr     r0, =motors_vec                 // setup motor vector
    ldr     r1, =TACHO_RAMPTIME_MS          // Ramp down duration (ms)
    bl      multi_set_tacho_ramp_down_sp

    // Setup motor speed
    ldr     r0, =motors_vec                 // setup motor vector
    mov     r1, #TACHO_MAX_SPEED            // Target speed of  motor
    bl      multi_set_tacho_speed_sp

    // Setup motor stop mode
    ldr     r0, =motors_vec                 // setup motor vector
    mov     r1, #TACHO_STOP_MODE            // How to stop the motor
    bl      multi_set_tacho_stop_action_inx

left_inittarget:
    mov     r0, r4                          // setup left motor sequence number
    ldr     r1, =left_tacho_targetpos
    bl      get_tacho_position              // Record initial target tacho position

right_inittarget:
    mov     r0, r5                          // setup right motor sequence number
    ldr     r1, =right_tacho_targetpos
    bl      get_tacho_position              // Record initial target tacho position

    mov     r6, #NUM_LOOPS                  // Setup loop count

loop:
    ldr     r0, =loopstr
    bl      prog_content2

    mov     r0, r6                          // Display loop counter
    mov     r1, #2                          // Right aligned 2 digit counter
    bl      prog_display_integer_aligned

    // Reset Coroutines for tacho_loop
    CORO_CONTEXT_INIT left_tacho
    CORO_CONTEXT_INIT right_tacho

    // Setup number of motors for coroutine dispatcher
    mov     r7, #2

    // initialize num_running_motors synchronization variable
    ldr     r1, =num_running_motors
    mov     r0, #0
    str     r0, [r1]

tacho_loop:
    CORO_CALL   left_tacho                  // Complete one 360 deg rotation
    cmp         r0, #CO_END
    subeq       r7, r7, #1
    CORO_CALL   right_tacho                 // Complete one 360 deg rotation
    cmp         r0, #CO_END
    subeq       r7, r7, #1
    cmp         r7, #0
    bgt         tacho_loop

    subs    r6, r6, #1                      // Continue until done
    bne     loop

exit:
    bl      stop_and_release_tachos
    bl      prog_exit
    pop     {pc}

    .end
