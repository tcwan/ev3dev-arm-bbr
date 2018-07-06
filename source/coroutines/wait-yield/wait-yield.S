/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  wait-yield.S
 *  \brief  produce consume behavior using coroutines.
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "arm-coroutine.h"

	.equiv	SLEEP_DURATION, 1
	.equiv	NUM_LOOPS, 10

	.data
	.align

	CORO_CONTEXT producer
	CORO_CONTEXT consumer

	CORO_LOCAL num, word, 0
	CORO_LOCAL item, word, 0

	.align

titlestr:	.asciz "Produce-Consume Using Wait-Yield\n"
producestr:	.asciz "Produce: %d\n"
consumestr: .asciz "Consume: %d\n"

	.code 32
	.text
	.align

is_not_empty:
	ldr		r0, =num
	ldr		r0, [r0]
	mov		pc, lr

is_empty:
	ldr		r0, =num
	ldr		r0, [r0]
	teq		r0, #0
	moveq	r0, #TRUE				// Set to TRUE if empty
	movne	r0, #FALSE				// Set to FALSE if not empty
	mov		pc, lr

	CORO_START producer
producing:
	CORO_WAIT	is_empty
	ldr		r0, =producestr
	ldr		r2, =item
	ldr		r1, [r2]
	add		r1, r1, #1
	str		r1, [r2]				// Increment item
	bl		printf					// Display item value

	ldr		r0, =num
	ldr		r1, [r0]
	add		r1, r1, #1
	str		r1, [r0]				// Update num

	CORO_YIELD
	b	producing
	CORO_END

	CORO_START consumer
consuming:
	CORO_WAIT	is_not_empty
	ldr		r0, =consumestr
	ldr		r1, =item
	ldr		r1, [r1]
	bl		printf					// Display item value

	ldr		r0, =num
	ldr		r1, [r0]
	sub		r1, r1, #1
	str		r1, [r0]				// update num

	CORO_YIELD
	b		consuming
	CORO_END

	.global main
main:
	push	{lr}
	ldr		r0, =titlestr
	bl		printf
	mov		r0, #SLEEP_DURATION
	bl		sleep

	mov		r4, #NUM_LOOPS

loop:
	// Start the consumer first to test CORO_WAIT semantics
	CORO_CALL	consumer
	CORO_CALL	producer
#if 0
	CORO_CALL consumer			// Calling producer or consumer with different frequency can still work
#endif

	subs	r4, r4, #1
	bne		loop
exit:
	// We have one unconsumed item left
	pop		{pc}

	.end
