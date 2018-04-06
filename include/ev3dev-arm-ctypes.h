/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   ev3dev-arm-ctypes.h
 *  \brief  ARM-BBR C type definitions
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once

#ifndef __ASSEMBLY__

/** @addtogroup typesAndUtils */
/*@{*/

typedef unsigned char U8; /**< Unsigned 8-bit integer. */
typedef signed char S8; /**< Signed 8-bit integer. */
typedef unsigned short U16; /**< Unsigned 16-bit integer. */
typedef signed short S16; /**< Signed 16-bit integer. */
typedef unsigned long U32; /**< Unsigned 32-bit integer. */
typedef signed long S32; /**< Signed 32-bit integer. */

typedef U8 bool; /**< Boolean data type. */
#define FALSE (0) /**< False boolean value. */
#define TRUE (!FALSE) /**< True boolean value. */

#ifndef NULL
/** Definition of the NULL pointer. */
#define NULL ((void*)0)
#endif

#endif

/*@}*/
