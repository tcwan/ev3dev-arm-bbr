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

	.data

printstr:	.asciz "Hello, ARM World!\n"

	.code 32
	.text
	.align
	.global main

main:
	push		{lr}
	bl		prog_init
	ldr		r0, =printstr
	bl		printf
	bl		prog_shutdown
	pop		{pc}

