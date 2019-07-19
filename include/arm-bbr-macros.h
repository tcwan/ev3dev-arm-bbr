/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   arm-bbr-macros.h
 *  \brief  Behavior Based Robotics Coroutine Macros
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 *  \defgroup bbr Behavior Based Robotics Coroutines in ARM Assembly
 *
 *
 *  \code
 *
 *	BEHAVIOR_PROLOGUE behavior
 *
 *	BEHAVIOR_EPILOGUE behavior
 *
 *
 *	CALL_BEHAVIOR behavior
 *
 *  \endcode
 *
 *  \{
 */

#pragma once

#ifdef __ASSEMBLY__

#include "arm-coroutine.h"


/** DEFINE_BHVR_SUPPRESS
 *
 *    Macro to define bhvr_suppress
 *
 * Parameters:
 *   None
 * Returns:
 *   None
 *
 *
 **/
	.macro	DEFINE_BHVR_SUPPRESS
	.data
bhvr_suppress:	.byte	TRUE
	.endm

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


/** BEHAVIOR_PROLOGUE
 *
 *	  Specify Behavior Coroutine Preamble (standard processing steps)
 *
 *    The logic checks that the behavior is not suppressed, and the trigger is activated
 *    then execute the behavior code (and Suppress lower priority behaviors).
 *
 *    If the behavior is not triggered, the coroutine is reset for next invocation
 *
 *    Need to provide:
 *    - trigger_\behavior routine that returns TRUE if behavior should be activated
 *
 *    WARNING: Do not use push / pop inside behavior routines if you want to set Debugger
 *             breakpoints or step through the behavior routine, the Debugger will hang
 *
 * Parameters:
 *   behavior: Name of Behavior
 * Returns:
 *   None
 **/
 	.macro	BEHAVIOR_PROLOGUE behavior
     // Coroutine Variables
 	CORO_CONTEXT bhvr_\behavior
 	CORO_START	bhvr_\behavior

check_trigger_\behavior:
	bl		trigger_\behavior		// Check activation conditions
	cmp		r0, #TRUE
	beq		exec_\behavior			// Activated, so continue

reset_\behavior:
	CORO_RESTART					// Behavior not activated, yield

exec_\behavior:
	set_bhvr_suppress TRUE			// Suppress other behaviors
	.endm


/** BEHAVIOR_EPILOGUE
 *
 *	  Specify Behavior Coroutine Epilogue (standard processing steps)
 *
 *    The EPILOGUE just yields the processor, and loops back to the start of the behavior coroutine
 *    for the next invocation to check if it was Suppressed, triggered, etc.
 *
 * Parameters:
 *   behavior: Name of Behavior
 * Returns:
 *   None
 **/
 	.macro	BEHAVIOR_EPILOGUE behavior
 	CORO_YIELD
 	b		check_trigger_\behavior
#if 0
	// Not Needed since we never execute it
 	CORO_END
#endif
	.endm

/** BEHAVIOR_TRIGGER
 *
 *	  Define Behavior Trigger routine name
 *
 *    The trigger routine name definition
 *
 * Parameters:
 *   behavior: Name of Behavior
 * Should Return:
 *   r0: TRUE = Behavior triggered, FALSE = Behavior not triggered
 **/
	.macro	BEHAVIOR_TRIGGER behavior
trigger_\behavior:
	.endm


/** CALL_BEHAVIOR
 *
 *	  Call Non-suppressed Behavior Coroutine using the behavior name
 *
 * Parameters:
 *   behavior: Name of Behavior
 * Returns:
 *   None
 **/
 	.macro	CALL_BEHAVIOR behavior
 	get_bhvr_suppress				// r0: Supressed flag (Boolean)
	cmp		r0, #FALSE
 	beq		call_\behavior

 reinit_\behavior:
 	CORO_CONTEXT_INIT bhvr_\behavior // reset behavior coroutine
	b		exit_call_\behavior

call_\behavior:
 	CORO_CALL	bhvr_\behavior

exit_call_\behavior:
	.endm

/** ACTUATOR_PROLOGUE
 *
 *	  Specify Actuator Coroutine Preamble (standard processing steps)
 *
 *    The logic checks that the actuator is enabled then execute the actuator code
 *
 *    WARNING: Do not use push / pop inside behavior routines if you want to set Debugger
 *             breakpoints or step through the behavior routine, the Debugger will hang
 *
 * Parameters:
 *   actuator: Name of Actuator
 * Returns:
 *   None
 **/
	.macro	ACTUATOR_PROLOGUE actuator
	 // Coroutine Variables
	CORO_CONTEXT actr_\actuator
	CORO_START	actr_\actuator

loop_\actuator:

check_trigger_\actuator:
	bl		trigger_\behavior		// Check activation conditions
	cmp		r0, #TRUE
	beq		exec_\behavior			// Activated, so continue

reset_\behavior:
	CORO_RESTART					// Behavior not activated, yield

exec_\behavior:
	set_bhvr_suppress TRUE			// Suppress other behaviors
	.endm


/** ACTUATOR_EPILOGUE
 *
 *	  Specify Actuator Coroutine Epilogue (standard processing steps)
 *
 *    The EPILOGUE just yields the processor, and loops back to the start of the actuator coroutine
 *    for the next invocation to check if it should continue executing.
 *
 * Parameters:
 *   behavior: Name of Behavior
 * Returns:
 *   None
 **/
	.macro	ACTUATOR_EPILOGUE actuator
	CORO_YIELD
	b		loop_\actuator
#if 0
	// Not Needed since we never execute it
	CORO_END
#endif
	.endm

/** CALL_ACTUATOR
 *
 *	  Call Non-suppressed Actuator Coroutine using the actuator name
 *
 * Parameters:
 *   actuator: Name of Actuator Routine
 * Returns:
 *   None
 **/
	.macro	CALL_ACTUATOR actuator
	//FIXME
	beq		call_\actuator

reinit_\actuator:
	CORO_CONTEXT_INIT actr_\actuator // reset behavior coroutine
	b		exit_call_\actuator

call_\actuator:
	CORO_CALL	actr_\actuator

exit_call_\actuator:
	.endm

#endif
/** \} */
