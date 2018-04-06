/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   ev3dev-arm-bbr.h
 *  \brief  Top level ARM-BBR Header File for all library function prototypes to be included in ARM-BBR programs
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

//
// This file is manually created from the common/include C headers
//
#pragma once

#include "ev3dev-arm-defines.h"

#ifdef __ASSEMBLY__

/* common/include/alerts.h */
	.extern alrt_hello
	.extern alrt_goodbye

/* common/include/scaffolding.h */
	.extern	prog_init
	.extern	prog_shutdown
	.extern prog_title
	.extern prog_content1
	.extern prog_content2
	.extern prog_contentX

#endif
