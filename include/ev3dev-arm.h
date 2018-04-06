/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   ev3dev-arm.h
 *  \brief  ARM-BBR macros to support ASM function prototypes
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once


#ifdef __ASSEMBLY__

#define NULL   0x0	    /* Stick the definition here instead of making types.h messy */
#define FALSE   0
#define TRUE    ~FALSE

#define TYPEDEF @
#define FUNCDEF @

#include "enum-asm.h"		// Enum macros
#include "interwork.h"		// Interworking macros

#endif

// Example of how to use ENUM* Macros
///** Enums to define Device Driver Module states */
//ENUM_0  INIT                /**< Driver Init Routine. */
//ENUM_N  SHUTDOWN            /**< Driver Shutdown Routine. */
//ENUM_N  SLEEP               /**< Driver Sleep Routine. */
//ENUM_N  WAKEUP              /**< Driver Wakeup Routine. */
//ENUM_N  POLL                /**< Driver Poll Routine. */
//ENUM_EQ NUM_STATES, POLL+1  /**< Enum value assignment */
//ENUM_EQ NEW_ENUM, 100       /**< Enum with value initialization */

