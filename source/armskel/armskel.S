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

	.equiv	NUM_LOOPS,	-5
	.equiv	SLEEP_DURATION, 3
	.equiv	SLEEP_LOOP, 1
	.equiv	TONE_FREQ,  800			// Note: Not all constant values are valid for MOV instruction
	.equiv	TONE_DUR,   400			// Note: Not all constant values are valid for MOV instruction

	.data

titlestr:	.asciz "Armskel Program"
promptstr:	.asciz "Welcome to EV3DEV-ARM-BBR"
contentstr:	.asciz "Hello ARM: "
byestr:		.asciz "Bye!                     "		// Clear any extended value displayed on the line


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

	mov		r0, #TONE_FREQ
	mov		r1, #TONE_DUR
	bl		alrt_tone

	mov		R4, #NUM_LOOPS

loop:
	ldr		r0, =contentstr
	bl		prog_content2

	mov		r0, r4
	// Change the following to prog_display_XXX for different output options
	bl		prog_display_hex32

	mov		r0, #SLEEP_LOOP
	bl		sleep

	cmp		R4, #0
	subgts	R4, R4, #1
	addlts  R4, R4, #1
	bne		loop

done:
	ldr		r0, =byestr
	bl		prog_content2


	bl		prog_shutdown
	pop		{pc}

