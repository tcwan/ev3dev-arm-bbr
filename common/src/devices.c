/*
     ____ __     ____   ___    ____ __         (((((()
    | |_  \ \  /   ) ) | |  ) | |_  \ \  /  \(@)- /
    |_|__  \_\/  __)_) |_|_/  |_|__  \_\/   /(@)- \
                                               ((())))
 *//**
 *  \file   devices.c
 *  \brief  ARM-BBR devices (sensors and motors) configuration routines
 *  \author  See AUTHORS for a full list of the developers
 *  \copyright  See the LICENSE file.
 */

#include <stdlib.h>
#include "ev3dev-arm-ctypes.h"
#include "devices.h"
#include <stdio.h>

#define ENABLE_INLINE

#ifdef ENABLE_INLINE
#define INLINE inline
#else
#define INLINE
#endif

/* Internal Routines */
bool _is_sn_identical_and_valid(U8 port_sn, U8 type_sn) {
	return ((port_sn == type_sn) && (port_sn != DESC_LIMIT) && (type_sn != DESC_LIMIT));
}


/* Convert a Sensor Type into the appropriate Port Mode for configuring set_port_mode_inx() */
INX_T ev3_sensor_port_mode_inx(INX_T type_inx ) {

	switch ( type_inx ) {
	case EV3_ANALOG_XX:
		return INPUT_EV3_ANALOG;
	case NXT_ANALOG:
		return INPUT_NXT_ANALOG;
	case PIXY_LEGO:
		return INPUT_NXT_I2C;
	case DI_DFLEX:
		return NXT_ANALOG;
	case FCL_9DOF:
	case FCL_ADC:
	case FCL_ALTITUDE:
	case FCL_GESTURE:
	case FCL_HUMIDITY:
	case FCL_IR:
	case FCL_LIGHT:
		return INPUT_EV3_UART;
	case HT_NXT_COLOR:
	case HT_NXT_ANGLE:
	case HT_NXT_ACCEL:
	case HT_NXT_BAROMETRIC:
	case HT_NXT_COLOR_V2:
		return INPUT_NXT_I2C;
	case HT_NXT_EOPD:
	case HT_NXT_FORCE:
	case HT_NXT_GYRO:
		return NXT_ANALOG;
	case HT_NXT_IR_LINK:
	case HT_NXT_IR_RECEIVER:
	case HT_NXT_PIR:
	case HT_NXT_COMPASS:
		return INPUT_NXT_I2C;
	case HT_NXT_MAG:
		return NXT_ANALOG;
	case HT_NXT_IR_SEEK_V2:
	case HT_NXT_SMUX:
	case HT_SUPER_PRO:
		return INPUT_NXT_I2C;
	case LEGO_EV3_US:
	case LEGO_EV3_GYRO:
	case LEGO_EV3_COLOR:
		return INPUT_EV3_UART;
	case LEGO_EV3_TOUCH:
		return INPUT_EV3_ANALOG;
	case LEGO_EV3_IR:
		return INPUT_EV3_UART;
	case WEDO_HUB:
		return PORT_MODE__NONE_;					// FIXME: USB Port (?)
	case WEDO_MOTION:
	case WEDO_TILT:
		return WEDO_AUTO;
	case LEGO_POWER_STORAGE:
	case LEGO_NXT_TEMP:
		return INPUT_NXT_I2C;
	case LEGO_NXT_TOUCH:
	case LEGO_NXT_LIGHT:
	case LEGO_NXT_SOUND:
		return INPUT_NXT_ANALOG;
	case LEGO_NXT_US:
		return INPUT_NXT_I2C;
	case MI_XG1300L:
	case MS_ABSOLUTE_IMU:
	case MS_ANGLE:
	case MS_LIGHT_ARRAY:
	case MS_LINE_LEADER:
	case MS_NXTCAM:
	case MS_NXTCAM5:
	case MS_8CH_SERVO:
	case MS_PPS58_NX:
	case MS_PIXY_ADAPTER:
		return INPUT_NXT_I2C;
	case MS_EV3_SMUX:
		return MS_EV3_SMUX_ANALOG;				// FIXME: There are two settings, MS_EV3_SMUX_ANALOG and MS_EV3_SMUX_UART
	case MS_NXTMMX:
		return MS_NXTMMX_TACHO_MOTOR;
	case MS_NXT_TOUCH_MUX:
		return INPUT_NXT_ANALOG;
	default:
		return PORT_MODE__NONE_;
	}
}


#if 0
// Not valid unless it has been setup using dvcs_config_dc_type_for_port() beforehand
INLINE bool ev3_search_dc_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn, U8 from ) {

	bool retval = false;
	U8 found_sn = DESC_LIMIT;
	INX_T found_type = DC_TYPE__UNKNOWN_;

	while ((found_type != type_inx) && (from < DESC_LIMIT)) {
		if ( ev3_search_dc_plugged_in( port, extport, &found_sn, from )) {
			found_type = ev3_dc_desc_type_inx(found_sn);
			retval = (found_type == type_inx);
		}
		from += 1;						// Setup for next device search in case (found_type != type_inx)
	}

	if (retval) {
		*sn = found_sn;							// Correct device type plugged into correct (valid) port
	}

	return retval;
}

// Not valid unless it has been setup using dvcs_config_servo_type_for_port() beforehand
INLINE bool ev3_search_servo_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn, U8 from ) {

	bool retval = false;
	U8 found_sn = DESC_LIMIT;
	INX_T found_type = SERVO_TYPE__UNKNOWN_;

	while ((found_type != type_inx) && (from < DESC_LIMIT)) {
		if ( ev3_search_servo_plugged_in( port, extport, &found_sn, from )) {
			found_type = ev3_servo_desc_type_inx(found_sn);
			retval = (found_type == type_inx);
		}
		from += 1;						// Setup for next device search in case (found_type != type_inx)
	}

	if (retval) {
		*sn = found_sn;							// Correct device type plugged into correct (valid) port
	}

	return retval;
}
#endif


INLINE bool ev3_search_sensor_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn, U8 from ) {

	bool retval = false;
	U8 found_sn = DESC_LIMIT;
	INX_T found_type = SENSOR_TYPE__UNKNOWN_;

	while ((found_type != type_inx) && (from < DESC_LIMIT)) {
		if ( ev3_search_sensor_plugged_in( port, extport, &found_sn, from )) {
			found_type = get_sensor_type_inx(found_sn);			// use get_xxx_type_inx() to access actual sysfs path
			retval = (found_type == type_inx);
		}
		from += 1;												// Setup for next device search in case (found_type != type_inx)
	}

	if (retval) {
		*sn = found_sn;											// Correct device type plugged into correct (valid) port
	}

	return retval;
}

INLINE bool ev3_search_tacho_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn, U8 from ) {

	bool retval = false;
	U8 found_sn = DESC_LIMIT;
	INX_T found_type = TACHO_TYPE__UNKNOWN_;

	while ((found_type != type_inx) && (from < DESC_LIMIT)) {
		if ( ev3_search_tacho_plugged_in( port, extport, &found_sn, from )) {
			found_type = get_tacho_type_inx(found_sn);			// use get_xxx_type_inx() to access actual sysfs path
			retval = (found_type == type_inx);
		}
		from += 1;												// Setup for next device search in case (found_type != type_inx)
	}

	if (retval) {
		*sn = found_sn;											// Correct device type plugged into correct (valid) port
	}

	return retval;
}

/* Public Routines */
bool dvcs_search_sensor_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn ) {

	return ev3_search_sensor_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function
}

bool dvcs_search_tacho_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn) {

	return ev3_search_tacho_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function

}

bool dvcs_config_dc_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn ) {

	bool retval = false;
	uint8_t sn_port;

	INX_T port_mode = OUTPUT_DC_MOTOR;


	sn_port = ev3_search_port( port, extport );
	set_port_mode_inx( sn_port, port_mode );
	retval = (get_port_mode_inx(sn_port) == port_mode);
	if (retval) {
		retval = ev3_search_dc_plugged_in( port, extport, sn, 0 );
		if (retval) {
			retval = (get_dc_type_inx(*sn) == type_inx);			// use get_xxx_type_inx() to access actual sysfs path
		}
	}

	return retval;
}

bool dvcs_reset_port_for_dc(U8 sn ) {
	uint8_t sn_port = ev3_dc_desc_port(sn);
	return (set_port_mode_inx(sn_port, OUTPUT_AUTO) > 0) ? true : false;
}


bool dvcs_config_sensor_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn ) {

	bool retval = false;
	uint8_t sn_port;
	INX_T port_mode = ev3_sensor_port_mode_inx(type_inx);
	char *sensor_type = (char *) ev3_sensor_type(type_inx);

	sn_port = ev3_search_port( port, extport );
	set_port_mode_inx( sn_port, port_mode );
	retval = (get_port_mode_inx(sn_port) == port_mode);

	if (retval) {
		set_port_set_device(sn_port, sensor_type);
		retval = ev3_search_sensor_plugged_in( port, extport, sn, 0 );
		if (retval) {
			retval = (get_sensor_type_inx(*sn) == type_inx);		// use get_xxx_type_inx() to access actual sysfs path
		}
	}

	return retval;

}

bool dvcs_reset_port_for_sensor(U8 sn ) {
	uint8_t sn_port = ev3_sensor_desc_port(sn);
	return (set_port_mode_inx(sn_port, INPUT_AUTO) > 0) ? true : false;
}

#if 0
// Not tested (no hardware)
bool dvcs_config_servo_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn ) {

	bool retval = false;
	uint8_t sn_port;

	INX_T port_mode = OUTPUT_TACHO_MOTOR;							// FIXME: Need to verify if this is correct

	sn_port = ev3_search_port( port, extport );
	set_port_mode_inx( sn_port, port_mode );
	retval = (get_port_mode_inx(sn_port) == port_mode);
	if (retval) {
		retval = ev3_search_servo_plugged_in( port, extport, sn, 0 );
		if (retval) {
			retval = (get_servo_type_inx(*sn) == type_inx);			// use get_xxx_type_inx() to access actual sysfs path
		}
	}

	return retval;

}

bool dvcs_reset_port_for_servo(U8 sn ) {
	uint8_t sn_port = ev3_servo_desc_port(sn);
	return (set_port_mode_inx(sn_port, OUTPUT_AUTO) > 0) ? true : false;
}

#endif
