/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   arm-coroutine.h
 *  \brief  Coroutine defintions for Assembly Language Routines
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 *  \defgroup coro Coroutines in ARM Assembly
 *
 *  Coroutine mechanics, implemented using the ARM Assembly Language Macros.
 *  Adapted from "coroutines.h" written by Vitaly Kravtsov (in4lio@gmail.com)
 *  (Based on Simon Tatham "Coroutines in C").
 *
 *  Note: This version is non-reentrant due to use of CORO_LOCAL variable in the data section
 *  WARNING: This version is not interworking compliant
 *
 *  \code
 *  	.data
 *  	.align 2
 *  CORO_LOCAL b, word, 0
 *
 *  CORO_CONTEXT A
 *  CORO_CONTEXT B
 *
 *  	.text
 *
 *  CORO_START A
 *      // ...
 *      CORO_YIELD
 *  CORO_END
 *
 *  CORO_START B
 *      // ...
 *      CORO_WAIT cont_subroutine 
 *  CORO_END
 *
 * main:
 * 		// ...
 * 		CORO_CALL A 
 * 		CORO_CALL B
 * 		// exit condition test
 * 		bne main
 *
 *  \endcode
 *
 *  Any local variables which need to be persistent across a coroutine switching
 *  must be declared in the data section (CORO_LOCAL).
 *
 *  \{
 */


#pragma once

#ifdef __ASSEMBLY__

#include "arm-stddef.h"
#include "enum-asm.h"

ENUM_0	CO_READY
ENUM_N	CO_WAIT
ENUM_N	CO_YIELD
ENUM_N	CO_END
ENUM_N	CO_SKIP

/**
 *  \brief Define the coroutine context (a pointer to label) and initialize it to NULL.
 *  \param name Coroutine name.
 */
	.macro	CORO_CONTEXT name
	.data
	.align 2
co_\name:	.word	NULL
	.endm

/**
 *  \brief Declare the local variable that preserves a value across a coroutine switching.
 *  \param name local variable name.
 *  \param type data type (byte, word, etc.)
 *  \param val initialization value.
 */
	.macro	CORO_LOCAL	name, type, val
	.data
\name:	.\type	\val
	.endm

/**
 *  \brief Define the coroutine.
 *  \param name Coroutine name.
 *
 *  This macro combines CORO_DEFINE and CORO_BEGIN functionality
 *  R0 (preserved) is address of context pointer (&co_p) on entry
 *
 *  Note: The coroutine name is global in scope
 */
	.macro	CORO_START name
	.text
	.align 4
	.global	coro_\name
coro_\name:
	push	{r0, lr}					// Keep co_p it for CORO_END use
	ldr		r0, [r0]					// retrieve *co_p
	teq		r0, #NULL					// is context pointer (*co_p) valid?
	beq		1f							// Skip if *co_p is NULL
	bx		r0							// branch to current context
1:
	.endm

/**
 *  \brief The coroutine end.
 *  \return coroutine status
 *
 *  R0 is retrieved from the stack (preserved by CORO_START)
 *  R1 is modified in this macro (not preserved per AAPCS)
 */
	.macro	CORO_END
	pop		{r0, lr}					// Restore co_p
	ldr		r1, =2f						// Load exit Status instruction address
	str		r1, [r0]
2:
	mov		r0, #CO_END					// return status
	bx		lr							// return to caller
	.endm

/**
 *  \brief Switching to the next coroutine.
 *  \return coroutine status
 *
 *  R0 is retrieved from the stack (preserved by CORO_START)
 *  R1 is modified in this macro (not preserved per AAPCS)
 */
	.macro	CORO_YIELD
	pop		{r0, lr}					// Restore co_p
	ldr		r1, =3f						// Load coroutine resume address
	str		r1, [r0]
	mov		r0, #CO_YIELD				// return status
	bx		lr							// return to caller
3:
	.endm

/**
 *  \brief Waiting for the condition is true.
 *  \param cont_eval_function Continue evaluation function (returns non-zero/TRUE to continue, or FALSE to wait).
 *  \return coroutine status
 *
 *  R0 is retrieved from the stack (preserved by CORO_START)
 *  R1 is modified in this macro (not preserved per AAPCS)
 *
 *  Note: This version differs from the C code by not updating *co_p unless we have to wait
 */
	.macro	CORO_WAIT cont_eval_function

4:
	bl		\cont_eval_function			// call cont_eval_function to determine whether to continue (non-zero/TRUE) or wait (FALSE)
	teq		r0, #FALSE
	bne		5f							// Continue is TRUE, so skip waiting
	// Continue is FALSE
	pop		{r0, lr}					// Restore co_p
	ldr		r1, =4b						// Load coroutine resume address to continue waiting
	str		r1, [r0]
	mov		r0, #CO_WAIT				// return status
	bx		lr							// return to caller
5:
	.endm

/**
 *  \brief Restart the coroutine.
*  \return coroutine status
 *
 *  R0 is retrieved from the stack (preserved by CORO_START)
 *  R1 is modified in this macro (not preserved per AAPCS)
 */

	.macro	CORO_RESTART
	pop		{r0, lr}					// Restore co_p
	mov		r1, #NULL					// Set pointer to NULL
	str		r1, [r0]
	mov		r0, #CO_YIELD				// return status
	bx		lr							// return to caller
	.endm

/**
 *  \brief Quit the coroutine.
 */
#define CORO_QUIT	CORO_END


/**
 *  \brief Call the coroutine.
 *  \param name Coroutine name.
 */
	.macro	CORO_CALL name
	ldr		r0, =co_\name				// address of context pointer
	bl		coro_\name
	.endm

/**
 *  \brief Checking the coroutine is not completed.
 *  \return TRUE if alive
 *
 *  To be used immediate after a CORO_CALL to check its return status
 *  FIXME: This is valid for ARM state only due to conditional execution instructions
 *
 *  Note: This macro is not intended for public use
 */

	.macro	CORO_ALIVE
	cmp		r0, #CO_END
	movlos	r0, #TRUE
	movhss	r0, #FALSE
	.endm

/**
 *  \brief Start and waiting for the child coroutine until it is completed.
 *  \param name Child coroutine.
 *
 *  R0 is retrieved from the stack (preserved by CORO_START)
 *  R1 is modified in this macro (not preserved per AAPCS)
 *
 *  Note: This version differs from the C code by not updating *co_p unless we have to wait
 */

	.macro	CORO_WAIT_CORO	name
6:
	bl		coro_\name
	cmp		r0, #CO_END
	beq		7f							// continue if coroutine ended, else wait
	// Coroutine not ended
	pop		{r0, lr}					// Restore co_p
	ldr		r1, =6b						// Load coroutine resume address to continue waiting
	str		r1, [r0]
	mov		r0, #CO_WAIT				// return status
	bx		lr							// return to caller
7:
	.endm

/**
 *  \brief Initialize the semaphore.
 *  \param name Semaphore name.
 *  \param val Semaphore capacity.
 *
 *  Note: We insert a semaphore check routine definition here as well
 *
 */
	.macro	SEMAPHORE_INIT name, val
	.data
	.align 2
sem_\name:	.word	\val

	.text
	.align 4
semcheck_\name:
	ldr		r0, =sem_\name
	ldr		r0, [r0]					// Get semaphore value
	bx		lr							// return to caller
	.endm

/**
 *  \brief Waiting and acquire the semaphore.
 *  \param name Semaphore name.
 *
 *  Note: R0 and R1 are destroyed
 */

	.macro	SEMAPHORE_ACQUIRE name
	CORO_WAIT semcheck_\name
	ldr		r0, =sem_\name
	ldr		r1, [r0]
	sub		r1, r1, #1
	str		r1, [r0]
	.endm

/**
 *  \brief Release the semaphore.
 *  \param name Semaphore name.
 *
 *  Note: R0 and R1 are destroyed
 */
	.macro SEMAPHORE_RELEASE name
	ldr		r0, =sem_\name
	ldr		r1, [r0]
	add		r1, r1, #1
	str		r1, [r0]
	.endm



#endif

/** \} */

