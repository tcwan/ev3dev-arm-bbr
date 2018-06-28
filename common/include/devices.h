/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   devices.h
 *  \brief  ARM-BBR devices (sensors and motors) configuration function prototypes
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#pragma once

#include <stdbool.h>
#include "ev3dev-arm-ctypes.h"

#include <ev3_both.h>
#include <ev3_tacho.h>

/** @addtogroup common */
/*@{*/

/** @defgroup devices Device Configuration
 *
 * The Devices library checks that a given motor or sensor is plugged into a specific port,
 * and perform device configuration for devices that are not automatically recognized.
 */
/*@{*/

/** Search for the sequence number for a specific dc motor type by plug-in attributes
 *
 * @param type_inx DC motor type.
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @param from Search initial value.
 * @return Flag - the DC motor is found.
 *
 * Note: DC motors are LEGO RCX or Powerfunctions motors which do not have feedback or control features
 *
 */
bool dvcs_search_dc_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from );

/** Search for the sequence number for a specific sensor type by plug-in attributes
 *
 * @param type_inx Sensor type.
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @param from Search initial value.
 * @return Flag - the sensor is found.
 *
 */
bool dvcs_search_sensor_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from );

/** Search for the sequence number for a specific servo motor type by plug-in attributes
 *
 * @param type_inx Servo motor type.
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @param from Search initial value.
 * @return Flag - the servo motor is found.
 *
 * Note: Servo motors are third party motors (i.e., EV3 and NXT motors are not servo motors)
 */
bool dvcs_search_servo_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from );

/** Search for the sequence number for a specific tacho motor type by plug-in attributes
 *
 * @param type_inx Tacho motor type.
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @param from Search initial value.
 * @return Flag - the tacho motor is found.
 *
 * Note: Tacho motors are LEGO motors (i.e., EV3 and NXT motors are tacho motors)
 *
 */
bool dvcs_search_tacho_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from );



/*@}*/
/*@}*/

