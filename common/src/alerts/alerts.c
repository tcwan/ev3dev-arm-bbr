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

void alrt_hello(bool audible) {
  if (!audible)
    return;
  nx_sound_freq(1000, 100);
  nx_systick_wait_ms(50);
  nx_sound_freq(2000, 100);
  nx_systick_wait_ms(900);
}

void alrt_goodbye(bool audible) {
  if (!audible)
    return;
  nx_sound_freq(2000, 100);
  nx_systick_wait_ms(50);
  nx_sound_freq(1000, 100);
  nx_systick_wait_ms(900);
}

