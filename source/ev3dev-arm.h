/** @file ev3dev-arm.h
 *  @brief Define macros to support shared C and ASM headers
 *
 * Copyright (c) 2007,2009, 2018
 * Thanks to Bartli (forum post @ embdev.net ARM programming with GCC/GNU tools forum)
 *
 * See AUTHORS for a full list of the developers.
 *
 * Redistribution of this file is permitted under the terms of the MIT License.
 */

#ifndef SOURCE_EV3DEV_ARM_H_
#define SOURCE_EV3DEV_ARM_H_

#ifdef __ASSEMBLY__

#define NULL   0x0	    /* Stick the definition here instead of making types.h messy */
#define FALSE   0
#define TRUE    ~FALSE

#define TYPEDEF @
#define FUNCDEF @

  .set last_enum_value, 0
  .macro enum_val name
  .equiv \name, last_enum_value
  .set last_enum_value, last_enum_value + 1
  .endm

#define ENUM_BEGIN  .set last_enum_value, 0

#define ENUM_VAL(name) enum_val name
#define ENUM_VALASSIGN(name, value)            \
  .set last_enum_value, value                 ;\
  enum_val name
#define ENUM_END(enum_name)

#else
/** Macro to control typedef generation
 *
 */
#define TYPEDEF typedef

/** Macro to control extern generation
 *
 */
#ifndef FUNCDEF
#define FUNCDEF extern
#endif

/** Macro to control typedef enum generation
 *
 */
#define ENUM_BEGIN typedef enum {

/** Macro to specify enum instance (auto value assignment)
 *
 */
#define ENUM_VAL(name) name,

/** Macro to control enum specification and value assignment
*
*/
#define ENUM_VALASSIGN(name, value) name = value,

/** Macro to control enum named type generation
 *
 */
#define ENUM_END(enum_name) } enum_name;

#endif

// Example of how to use ENUM* Macros
///** Enums to define Device Driver Module states */
//ENUM_BEGIN
//ENUM_VAL(INIT)             /**< Driver Init Routine. */
//ENUM_VAL(SHUTDOWN)         /**< Driver Shutdown Routine. */
//ENUM_VAL(SLEEP)            /**< Driver Sleep Routine. */
//ENUM_VAL(WAKEUP)           /**< Driver Wakeup Routine. */
//ENUM_VAL(POLL)             /**< Driver Poll Routine. */
//ENUM_END(nx_driver_default_cmd)

#endif /* SOURCE_EV3DEV_ARM_H_ */
