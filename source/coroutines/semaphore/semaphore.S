/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  semaphore.S
 *  \brief  produce consume behavior using Semaphores.
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "arm-coroutine.h"

    .equiv  SLEEP_DURATION, 1
    .equiv  NUM_LOOPS, 10

    .data
    .align

    CORO_CONTEXT producer
    CORO_CONTEXT consumer

    CORO_LOCAL item, word, 0

    SEMAPHORE_INIT  item_produced, 0
    SEMAPHORE_INIT  item_consumed, 1

    .align

titlestr:   .asciz "Produce-Consume Using Semaphores\n"
producestr: .asciz "Produce: %d\n"
consumestr: .asciz "Consume: %d\n"

    .code 32
    .text
    .align

    CORO_START producer
producing:
    SEMAPHORE_ACQUIRE item_consumed
    ldr     r0, =producestr
    ldr     r2, =item
    ldr     r1, [r2]
    add     r1, r1, #1
    str     r1, [r2]                // Increment item
    bl      printf                  // Display item value
    SEMAPHORE_RELEASE item_produced
    b   producing
    CORO_END

    CORO_START consumer
consuming:
    SEMAPHORE_ACQUIRE item_produced
    ldr     r0, =consumestr
    ldr     r1, =item
    ldr     r1, [r1]
    bl      printf                  // Display item value
    SEMAPHORE_RELEASE item_consumed
    b       consuming
    CORO_END

    .global main
main:
    push    {lr}
    ldr     r0, =titlestr
    bl      printf
    mov     r0, #SLEEP_DURATION
    bl      sleep

    mov     r4, #NUM_LOOPS

loop:
    // Start consumer first to check semaphore correctness
    CORO_CALL consumer
    CORO_CALL producer
#if 0
    // Calling producer or consumer with different frequency can still work
    CORO_CALL consumer          
#endif
    subs    r4, r4, #1
    bne     loop
exit:
    // The last item produced is not consumed since we didn't call consumer
    pop     {pc}

    .end
