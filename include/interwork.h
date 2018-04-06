/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   interwork.h
 *  \brief  ARM-BBR Interworking macros for Assembly Language Routines
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */


#pragma once

#ifdef __ASSEMBLY__
/** Macro to call Interworked ARM Routine Directly
 *
 *      arm_dcall       <target_arm_routine>
 *
 */
	.macro arm_dcall arm_routine
	BL     \arm_routine        @ Linker will generate veneer automatically
	.endm

/** Macro to call Interworked ARM Routine via Register (Indirect)
 *
 *      arm_rcall       <register>
 *
 */
	.macro arm_rcall register
	MOV    LR, PC
	BX     \register           @ register setup before indirect call
	.endm

/** Macro to declare Interworking ARM Routine
 *
 *      arm_interwork   <arm_routine_name>
 *
 */
	.macro arm_interwork arm_routine
	.align 2
	.arm
	.type \arm_routine, %function   @ Needed by new binutils (>2.21)
	.global \arm_routine
\arm_routine:
	.endm
	
/** Macro to call Interworked Thumb Routine Directly
 *
 *      thumb_dcall     <target_thumb_routine>
 *
 */
	.macro thumb_dcall thumb_routine
	BL     \thumb_routine      @ Linker will generate veneer automatically
	.endm

/** Macro to call Interworked Thumb Routine via Register (Indirect)
 *
 *      thumb_rcall       <register>
 *
 */
	.macro thumb_rcall register
	B	   0f
9:
	BX     \register
0:
	BL     9b                  @ register setup before indirect call
	.endm
	
/** Macro to declare Interworking Thumb Routine
 *
 *      thumb_interwork <thumb_routine_name>
 *
 */
	.macro thumb_interwork thumb_routine
	.align 2
	.thumb_func
	.type \thumb_routine, %function   @ Needed by new binutils (>2.21)
	.global \thumb_routine
\thumb_routine:
	.endm

/** Macro to return from Interworking Thumb Routine
 *
 *      thumb_iret <register>
 *
 */
	.macro thumb_iret register
	pop		{\register}
	bx		\register
	.endm


#endif
