/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  helloarm.S
 *  \brief  ev3dev-arm-bbr Hello World example.
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

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
	pop		{pc}

	.end
