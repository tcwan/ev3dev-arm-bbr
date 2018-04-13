/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file  armskel.S
 *  \brief  ev3dev-arm-bbr skeleton application.
 *  \author  Tat-Chee Wan (tcwan@usm.my)
 *  \copyright  See the LICENSE file.
 */

#define __ASSEMBLY__

#include "ev3dev-arm-bbr.h"
#include "ev3.h"

	.equiv	SLEEP_DURATION, 3

	.data

titlestr:	.asciz "Armskel Program"
promptstr:	.asciz "Welcome to EV3DEV-ARM-BBR"
contentstr:	.asciz "Hello ARM!"

	.code 32
	.text
	.align
	.global main

main:
	push		{lr}
	bl		prog_init

	ldr		r0, =titlestr
	bl		prog_title

	mov		r0, #SLEEP_DURATION
	bl		sleep

	ldr		r0, =promptstr
	bl		prog_content1

	mov		r0, #SLEEP_DURATION
	bl		sleep

	ldr		r0, =contentstr
	bl		prog_content2

	mov		r0, #SLEEP_DURATION
	bl		sleep

	bl		prog_shutdown
	pop		{pc}

