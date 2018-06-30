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

/* Internal Routines */
bool _is_sn_identical_and_valid(uint8_t port_sn, uint8_t type_sn) {
	return ((port_sn == type_sn) && (port_sn != DESC_LIMIT) && (type_sn != DESC_LIMIT));
}

inline bool ev3_search_dc_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from ) {

	bool retval = false;
	uint8_t port_sn = DESC_LIMIT;
	uint8_t type_sn = DESC_LIMIT;

	if (ev3_search_dc_plugged_in(port, extport, &port_sn, from) \
			&& ev3_search_dc(type_inx, &type_sn, from)) {
		retval = _is_sn_identical_and_valid(port_sn, type_sn);	// Correct motor type plugged into correct (valid) port
		if (retval)
			*sn = port_sn;

	}

	return retval;
}

inline bool ev3_search_sensor_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from ) {

	bool retval = false;
	uint8_t port_sn = DESC_LIMIT;
	uint8_t type_sn = DESC_LIMIT;

	if (ev3_search_sensor_plugged_in(port, extport, &port_sn, from) \
			&& ev3_search_sensor(type_inx, &type_sn, from)) {
		retval = _is_sn_identical_and_valid(port_sn, type_sn);	// Correct motor type plugged into correct (valid) port
		if (retval)
			*sn = port_sn;

	}

	return retval;
}
inline bool ev3_search_servo_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from ) {

	bool retval = false;
	uint8_t port_sn = DESC_LIMIT;
	uint8_t type_sn = DESC_LIMIT;

	if (ev3_search_servo_plugged_in(port, extport, &port_sn, from) \
			&& ev3_search_servo(type_inx, &type_sn, from)) {
		retval = _is_sn_identical_and_valid(port_sn, type_sn);	// Correct motor type plugged into correct (valid) port
		if (retval)
			*sn = port_sn;

	}

	return retval;
}

inline bool ev3_search_tacho_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn, uint8_t from ) {

	bool retval = false;
	uint8_t port_sn = DESC_LIMIT;
	uint8_t type_sn = DESC_LIMIT;

	if (ev3_search_tacho_plugged_in(port, extport, &port_sn, from) \
			&& ev3_search_tacho(type_inx, &type_sn, from)) {
		retval = _is_sn_identical_and_valid(port_sn, type_sn);	// Correct motor type plugged into correct (valid) port
		if (retval)
			*sn = port_sn;

	}

	return retval;
}

/* Public Routines */
bool dvcs_search_dc_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn ) {

	return ev3_search_dc_type_for_port(type_inx, port, extport, sn, 0);				// Wrapper for actual function
}

bool dvcs_search_sensor_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn ) {

	return ev3_search_sensor_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function
}

bool dvcs_search_servo_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn ) {

	return ev3_search_servo_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function

}

bool dvcs_search_tacho_type_for_port(INX_T type_inx, uint8_t port, uint8_t extport, uint8_t *sn) {

	return ev3_search_tacho_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function

}
