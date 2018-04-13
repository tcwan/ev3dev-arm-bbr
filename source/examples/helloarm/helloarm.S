/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  helloarm.S
 *  \brief  Standard C-Library Hello World example.
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

// STDIO-only example program

	.equiv	SLEEP_DURATION, 5

	.data
	.align

printstr:	.asciz "Hello, ARM World!\n"

	.code 32
	.text
	.align
	.global main

main:
	push		{lr}
	ldr		r0, =printstr
	bl		printf
	mov		r0, #SLEEP_DURATION
	bl		sleep
	pop		{pc}

	.end
