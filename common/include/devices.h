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

#include <ev3.h>
#include <ev3_dc.h>
#include <ev3_port.h>
#include <ev3_sensor.h>
#include <ev3_servo.h>
#include <ev3_tacho.h>

/** @addtogroup common */
/*@{*/

/** @defgroup device-autoconfig Device Auto-Configuration
 *
 * The Devices library checks that a given auto-configurable motor or sensor
 * is plugged into a specific port.
 * The routines should be used only after the device type has been initialized
 * using ev3_xxx_init()
 *
 *     e.g.: LEGO NXT and EV3 motors
 *           LEGO NXT and EV3 sensors (except LEGO NXT Sound Sensor)
 *           Most third party I2C and UART sensors
 */
/*@{*/


/** Search for the sequence number for a specific sensor type by plug-in attributes
 *
 * @param type_inx Sensor type. [From ev3_sensor.h]
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @return Flag - the sensor is found.
 *
 */
bool dvcs_search_sensor_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn );

/** Search for the sequence number for a specific tacho motor type by plug-in attributes
 *
 * @param type_inx Tacho motor type. [From ev3_tacho.h]
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @return Flag - the tacho motor is found.
 *
 * Note: Tacho motors are LEGO motors (i.e., EV3 and NXT motors are tacho motors)
 *
 */
bool dvcs_search_tacho_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn );

/*@}*/

/** @defgroup device-manualconfig Device Manual Configuration
 *
 * The Devices library configures a given port for a specific device type manually.
 * It is intended for use by devices that are not automatically recognized:
 *    e.g. LEGO Power Functions and RCX motors
 *         Third party motors and sensors (analog)
 *         Third party I2C sensors (some do not identify themselves properly)
 */
/*@{*/

/** Configure the specific dc motor type fpr a given port and find the sequence number
 *
 * @param type_inx DC motor type. [From ev3_dc.h]
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @return Flag - the DC motor is found.
 *
 * Note: DC motors are LEGO RCX or Powerfunctions motors which do not have feedback or control features
 *
 */
bool dvcs_config_dc_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn );

/** Reset the port mode to auto for the given motor
 *
 * @param sn sequence number.
 * @return Flag - the port is reset to auto
 *
 */
bool dvcs_reset_port_for_dc(U8 sn );

/** Configure the specific sensor type fpr a given port and find the sequence number
 *
 * @param type_inx Sensor type. [From ev3_sensor.h]
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @return Flag - the sensor is found.
 *
 */
bool dvcs_config_sensor_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn );

/** Reset the port mode to auto for the given sensor
 *
 * @param sn sequence number.
 * @return Flag - the port is reset to auto
 *
 */
bool dvcs_reset_port_for_sensor(U8 sn );

#if 0
// FIXME: TBD
/** Configure the specific tacho type fpr a given port and find the sequence number
 *
 * Note: This is needed for the BrickPi platform to connect to EV3 and NXT motors
 *
 * @param type_inx Sensor type. [From ev3_sensor.h]
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @return Flag - the sensor is found.
 *
 */
bool dvcs_config_tacho_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn );

/** Reset the port mode to auto for the given tacho
 *
 * @param sn sequence number.
 * @return Flag - the port is reset to auto
 *
 */
bool dvcs_reset_port_for_tacho(U8 sn );
#endif

#if 0
// Not tested (no hardware)
/** Configure the specific servo motor type fpr a given port and find the sequence number
 *
 * @param type_inx Servo motor type.  [From ev3_servo.h]
 * @param port EV3 port.
 * @param extport Extended port (used by Motor Multiplexers).
 * @param[out] sn Buffer for the sequence number.
 * @return Flag - the servo motor is found.
 *
 * Note: Servo motors are third party motors (i.e., EV3 and NXT motors are not servo motors)
 */
bool dvcs_config_servo_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn );

/** Reset the port mode to auto for the given servo
 *
 * @param sn sequence number.
 * @return Flag - the port is reset to auto
 *
 */
bool dvcs_reset_port_for_servo(U8 sn );

#endif

/*@}*/

/*@}*/

