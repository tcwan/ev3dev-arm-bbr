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
 *  \code
 *  	.data
 *  	.align
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
 *  must be declared static (CORO_LOCAL).
 *
 *  \{
 */


#pragma once

#ifdef __ASSEMBLY__

#include "ev3dev-arm-defines.h"

ENUM_0	CO_READY
ENUM_N	CO_WAIT
ENUM_N	CO_YIELD
ENUM_N	CO_END
ENUM_N	CO_SKIP

/**
 *  \brief Define the coroutine context (a pointer to label).
 *  \param name Coroutine name.
 */
	.macro	CORO_CONTEXT name
co_\name:	.word	NULL
	.endm

/**
 *  \brief Declare the local variable that preserves a value across a coroutine switching.
 *  \param name local variable name.
 *  \param type data type (byte, word, etc.)
 *  \param val initialization value.
 */
	.macro	CORO_LOCAL	name, type, val
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
	ldr		r1, =2f						// FIXME: Is this a valid macro expansion?
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
	ldr		r1, =3f						// FIXME: Is this a valid macro expansion?
	str		r1, [r0]
	mov		r0, #CO_YIELD				// return status
	bx		lr							// return to caller
3:
	.endm

/**
 *  \brief Waiting for the condition is true.
 *  \param cont_eval_function Continue evaluation function (returns TRUE to continue, or FALSE to wait).
 *  \return coroutine status
 *
 *  R0 is retrieved from the stack (preserved by CORO_START)
 *  R1 is modified in this macro (not preserved per AAPCS)
 *
 *  Note: This version differs from the C code by not updating *co_p unless we have to wait
 */
	.macro	CORO_WAIT cont_eval_function

4:
	blx		\cont_eval_function			// call cont_eval_function to determine whether to continue (TRUE) or wait (FALSE)
	teq		r0, #FALSE
	bne		5f							// Continue is TRUE, so skip waiting
	// Continue is FALSE
	pop		{r0, lr}					// Restore co_p
	ldr		r1, =4b						// FIXME: Is this a valid macro expansion?
	str		r1, [r0]
	mov		r0, #CO_WAIT					// return status
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
	blx		coro_\name
	cmp		r0, #CO_END
	beq		7f							// continue if coroutine ended, else wait
	// Coroutine not ended
	pop		{r0, lr}					// Restore co_p
	ldr		r1, =6b						// FIXME: Is this a valid macro expansion?
	str		r1, [r0]
	mov		r0, #CO_WAIT					// return status
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
sem_\name:	.byte	\val

	.text
semcheck_\name:
	ldr		r0, =sem_\name
	ldrb	r0, [r0]						// Get semaphore value
	bx		lr								// return to caller
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
	ldrb	r1, [r0]
	sub		r1, r1, #1
	strb	r1, [r0]
	.endm

/**
 *  \brief Release the semaphore.
 *  \param name Semaphore name.
 *
 *  Note: R0 and R1 are destroyed
 */
	.macro SEMAPHORE_RELEASE name
	ldr		r0, =sem_\name
	ldrb	r1, [r0]
	add		r1, r1, #1
	strb	r1, [r0]
	.endm


#else

typedef void * co_t;
typedef unsigned int semaphore_t;

enum {
	CO_READY,
	CO_WAIT,
	CO_YIELD,
	CO_END,
	CO_SKIP,
};

/**
 *  \brief Define the coroutine context (a pointer to label).
 *  \param name Coroutine name.
 */
#define CORO_CONTEXT( name ) \
	co_t co_##name

#define CORO_CONTEXT_INIT( name ) ({ \
	co_##name = NULL; \
})

/**
 *  \brief Declare the local variable that preserves a value across a coroutine switching.
 */
#define CORO_LOCAL  static

/**
 *  \brief Define the coroutine.
 *  \param name Coroutine name.
 */
#define CORO_DEFINE( name ) \
	int coro_##name( co_t *co_p )

/**
 *  \brief The coroutine beginning.
 *  \param initial The initial operation, executed whenever enter in the coroutine.
 */
#define CORO_BEGIN( initial ) ({ \
	initial; \
	if ( *co_p ) goto **co_p; \
})

/**
 *  \brief The coroutine end.
 *  \param final The final operation, executed whenever exit from the coroutine.
 *  \hideinitializer
 */
#define CORO_END( final ) ({ \
	__label__ L; \
	*co_p = &&L; \
L: \
	final; \
	return CO_END; \
})

/**
 *  \brief Switching to the next coroutine.
 *  \param final Final operation.
 */
#define CORO_YIELD( final ) ({ \
	__label__ L; \
	*co_p = &&L; \
	final; \
	return CO_YIELD; \
L:; \
})

/**
 *  \brief Waiting for the condition is true.
 *  \param cond Condition.
 *  \param ... Final operation.
 */
#define CORO_WAIT( cond, ... ) ({ \
	__label__ L; \
	*co_p = &&L; \
L: \
	if (!( cond )) { \
		__VA_ARGS__;  /* final */ \
		return CO_WAIT; \
	} \
})

/**
 *  \brief Restart the coroutine.
 *  \param final Final operation.
 */
#define CORO_RESTART( final ) ({ \
	*co_p = NULL; \
	final; \
	return CO_YIELD; \
})

/**
 *  \brief Quit the coroutine.
 *  \param final Final operation.
 */
#define CORO_QUIT( final )  CORO_END( final )

/**
 *  \brief Call the coroutine.
 *  \param name Coroutine name.
 */
#define CORO_CALL( name ) \
	coro_##name( &co_##name )

/**
 *  \brief Checking the coroutine is not completed.
 *  \param coro Result of the coroutine call.
 *  \return Alive flag.
 */
#define CORO_ALIVE( coro ) (( coro ) < CO_END )

/**
 *  \brief Start and waiting for the child coroutine is completed.
 *  \param coro Child coroutine.
 *  \param ... Final operation.
 */
#define CORO_WAIT_CORO( coro, ... ) \
	CORO_WAIT( !CORO_ALIVE( coro ), ## __VA_ARGS__ )

/**
 *  \brief Initialize the semaphore.
 *  \param name Semaphore name.
 *  \param val Semaphore capacity.
 */
#define SEMAPHORE_INIT( name, val ) ({ \
	name = val; \
})

/**
 *  \brief Waiting and acquire the semaphore.
 *  \param name Semaphore name.
 *  \param ... Final operation.
 */
#define SEMAPHORE_ACQUIRE( name, ... ) ({ \
	CORO_WAIT(( name > 0 ), ## __VA_ARGS__ ); \
	--name; \
})

/**
 *  \brief Release the semaphore.
 *  \param name Semaphore name.
 */
#define SEMAPHORE_RELEASE( name ) ({ \
	++name; \
})

#endif

/** \} */

