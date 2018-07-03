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

INLINE bool ev3_search_sensor_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn, U8 from ) {

	bool retval = false;
	U8 found_sn = DESC_LIMIT;
	INX_T found_type = SENSOR_TYPE__UNKNOWN_;

	while ((found_type != type_inx) && (from < DESC_LIMIT)) {
		if ( ev3_search_sensor_plugged_in( port, extport, &found_sn, from )) {
			found_type = ev3_sensor_desc_type_inx(found_sn);
			retval = (found_type == type_inx);
		}
		from += 1;						// Setup for next device search in case (found_type != type_inx)
	}

	if (retval) {
		*sn = found_sn;							// Correct device type plugged into correct (valid) port
	}

	return retval;
}

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

INLINE bool ev3_search_tacho_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn, U8 from ) {

	bool retval = false;
	U8 found_sn = DESC_LIMIT;
	INX_T found_type = TACHO_TYPE__UNKNOWN_;

	while ((found_type != type_inx) && (from < DESC_LIMIT)) {
		if ( ev3_search_tacho_plugged_in( port, extport, &found_sn, from )) {
			found_type = ev3_tacho_desc_type_inx(found_sn);
			retval = (found_type == type_inx);
		}
		from += 1;						// Setup for next device search in case (found_type != type_inx)
	}

	if (retval) {
		*sn = found_sn;							// Correct device type plugged into correct (valid) port
	}

	return retval;
}

/* Public Routines */
bool dvcs_search_dc_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn ) {

	return ev3_search_dc_type_for_port(type_inx, port, extport, sn, 0);				// Wrapper for actual function
}

bool dvcs_search_sensor_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn ) {

	return ev3_search_sensor_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function
}

bool dvcs_search_servo_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn ) {

	return ev3_search_servo_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function

}

bool dvcs_search_tacho_type_for_port(INX_T type_inx, U8 port, U8 extport, U8 *sn) {

	return ev3_search_tacho_type_for_port(type_inx, port, extport, sn, 0);			// Wrapper for actual function

}
