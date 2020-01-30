/*
	Copyright 2020 Kirill Kostiuchenko	<kisel2626@gmail.com>

	This file is part of the VESC firmware.

	The VESC firmware is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    The VESC firmware is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#ifndef APP_SKYPUFF_H_
#define APP_SKYPUFF_H_

#include <stdint.h>

/* --- This is common file for MCU and UI SkyPUFF apps --- */

// Do not forget to add next settings version command on skypuff_config struct update
typedef enum
{
    SK_COMM_ALIVE,
    SK_COMM_SETTINGS_V1,
} skypuff_custom_app_data_command;

// Winch FSM
typedef enum
{
    UNINITIALIZED,             // Released motor until some valid configuration set
    BRAKING,                   // Braking zone near take off
    BRAKING_EXTENSION,         // Braking after braking zone. Set long to disable automatic transition to UNWINDING. Manual possible.
    SLOWING,                   // Next to braking zone to slow down the motor
    SLOW,                      // Constant speed in direction to zero
    UNWINDING,                 // Low force rope tension during step up or unwinder mode
    REWINDING,                 // Fast rope winding to zero for unwinder mode
    PRE_PULL,                  // Pull the pilot while stays on the takeoff
    TAKEOFF_PULL,              // Takeoff pull
    PULL,                      // Nominal pull
    FAST_PULL,                 // Fast pull
    MANUAL_BRAKING,            // Any position braking caused by operator or communication timeout
    MANUAL_SLOW_SPEED_UP,      // Speed up until manual constant speed in direction to zero
    MANUAL_SLOW,               // Constant speed mode in direction to zero from any position
    MANUAL_SLOW_BACK_SPEED_UP, // Speed up back in direction from zero until manual constant speed
    MANUAL_SLOW_BACK,          // Constant speed mode in direction from zero
#ifdef DEBUG_SMOOTH_MOTOR
    MANUAL_DEBUG_SMOOTH, // Debug smooth motor movements with 'smooth' terminal commands
#endif
} skypuff_state;

// Winch settings
typedef struct
{
    float amps_per_kg;                  // Winch drive force coefficient
    int pull_applying_period;           // Milliseconds to apply pull force, amps_per_sec will be calculated from this delay
    int rope_length;                    // Winch rope length in tachometer steps (used by interface only)
    int braking_length;                 // Tachometer range of braking zone
    int braking_extension_length;       // Increase braking_length for passive winches when car drive 150m from takeoff
    int slowing_length;                 // Range after braking zone to slow down motor when unwinding to zero
    float slow_erpm;                    // Constant erpm in direction to zero
    int rewinding_trigger_length;       // Switch to fast rewinding state after going back this length
    int unwinding_trigger_length;       // Back to unwinding from rewinding if this range unwinded again
    float pull_current;                 // Winch normal pull force, usually pilot weight
    float pre_pull_k;                   // pre_pull_k * pull_current = pull current when pilots stays on the ground
    float takeoff_pull_k;               // takeoff_pull_k * pull_current = pull current during takeoff
    float fast_pull_k;                  // fast_pull_k * pull_current = pull current to get altitude fast
    int takeoff_trigger_length;         // Minimal PRE_PULL movement for transition to TAKEOFF_PULL
    int pre_pull_timeout;               // Timeout before saving position after PRE_PULL
    int takeoff_period;                 // Time of TAKEOFF_PULL and then switch to normal PULL
    float brake_current;                // Braking zone force, could be set high to charge battery driving away
    float slowing_current;              // Set zero to release motor when slowing or positive value to brake
    float manual_brake_current;         // Manual braking force
    float unwinding_current;            // Unwinding force
    float rewinding_current;            // Rewinding force
    float slow_max_current;             // Max force for constant slow speed
    float manual_slow_max_current;      // Max force for MANUAL_SLOW and MANUAL_SLOW_BACK
    float manual_slow_speed_up_current; // Speed up current for manual constant speed states
    float manual_slow_erpm;             // Constant speed for manual rotation
} skypuff_config;

// Drive settings part of mc_configuration
typedef struct
{
    int motor_poles;
    float wheel_diameter;
    float gear_ratio;
} skypuff_drive;

/*
	Smooth Motor Control

	Respect pilot and do not pull or release him too sharply.
	Unwinding current is minimal step of applying pull or brake.

	Use config.amps_per_sec as force changing speed and
	smooth_max_step_delay as maximum step delay.

	In case of different current and target modes, 
	switch instantly if force is less then unwinding 
	and smoothly decrease/increase until unwinding if above.

	Always brake instantly if braking zone.
*/
typedef enum
{
    MOTOR_RELEASED,
    MOTOR_CURRENT,
    MOTOR_BRAKING,
    MOTOR_SPEED,
} smooth_motor_mode;

// UI side use this too
inline const char *state_str(const skypuff_state s)
{
    switch (s)
    {
    case UNINITIALIZED:
        return "UNITIALIZED";
    case BRAKING:
        return "BRAKING";
    case BRAKING_EXTENSION:
        return "BRAKING_EXTENSION";
    case MANUAL_BRAKING:
        return "MANUAL_BRAKING";
    case MANUAL_SLOW_SPEED_UP:
        return "MANUAL_SLOW_SPEED_UP";
    case MANUAL_SLOW:
        return "MANUAL_SLOW";
    case MANUAL_SLOW_BACK_SPEED_UP:
        return "MANUAL_SLOW_BACK_SPEED_UP";
    case MANUAL_SLOW_BACK:
        return "MANUAL_SLOW_BACK";
    case UNWINDING:
        return "UNWINDING";
    case REWINDING:
        return "REWINDING";
    case SLOWING:
        return "SLOWING";
    case SLOW:
        return "SLOW";
    case PRE_PULL:
        return "PRE_PULL";
    case TAKEOFF_PULL:
        return "TAKEOFF_PULL";
    case PULL:
        return "PULL";
    case FAST_PULL:
        return "FAST_PULL";
#ifdef DEBUG_SMOOTH_MOTOR
    case MANUAL_DEBUG_SMOOTH:
        return "MANUAL_DEBUG_SMOOTH";
#endif
    default:
        return "UNKNOWN";
    }
}

inline const char *sk_command_str(const skypuff_custom_app_data_command c)
{
    switch (c)
    {
    case SK_COMM_ALIVE:
        return "SK_COMM_ALIVE";
    case SK_COMM_SETTINGS_V1:
        return "SK_COMM_SETTINGS_V1";
    default:
        return "SK_COMM_UNKNOWN";
    }
}

inline static const char *motor_mode_str(smooth_motor_mode m)
{
    switch (m)
    {
    case MOTOR_RELEASED:
        return "MOTOR_RELEASED";
    case MOTOR_BRAKING:
        return "MOTOR_BRAKING";
    case MOTOR_CURRENT:
        return "MOTOR_CURRENT";
    case MOTOR_SPEED:
        return "MOTOR_SPEED";
    default:
        return "MOTOR_UNKNOWN";
    }
}

#endif