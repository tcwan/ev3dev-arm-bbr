/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   arm-stddefh.h
 *  \brief  Define equivalent values for NULL, TRUE, and FALSE
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once


#ifdef __ASSEMBLY__

#define NULL   0x0
#define FALSE   0
#define TRUE    1				/* Follow <stdbool.h> convention */

#endif
