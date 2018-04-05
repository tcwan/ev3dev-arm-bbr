/** @file ev3dev-arm.h
 *  @brief Define macros to support ASM function prototypes
 *
 * Copyright (c) 2007,2009, 2018
 * Thanks to Bartli (forum post @ embdev.net ARM programming with GCC/GNU tools forum)
 *
 * See AUTHORS for a full list of the developers.
 *
 * Redistribution of this file is permitted under the terms of the MIT License.
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

