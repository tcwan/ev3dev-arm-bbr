/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   alerts.c
 *  \brief  ARM-BBR alerts routines
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#include <stdlib.h>

// Use the beep command to do the work for us
// TODO: Access the Speaker device via programming interfaces

#define HELLO_CMDSTR "beep -f 1000 -l 100 -D 50 -n -f 2000 -l 100 -D 100"
#define GOODBYE_CMDSTR "beep -f 2000 -l 100 -D 50 -n -f 1000 -l 100 -D 100"

void alrt_hello(bool audible) {
  if (!audible)
    return;
  system(HELLO_CMDSTR);
}

void alrt_goodbye(bool audible) {
  if (!audible)
    return;
  system(GOODBYE_CMDSTR);
}

