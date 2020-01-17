#include "qmlable_skypuff_types.h"

bool QMLable_skypuff_config::deserializeV1(VByteArray& from)
{
    if(from.length() < 109)
            return false;

    motor_poles = from.vbPopFrontUint8();
    gear_ratio = from.vbPopFrontDouble32Auto();
    wheel_diameter = from.vbPopFrontDouble32Auto();

    amps_per_kg = from.vbPopFrontDouble32Auto();
    amps_per_sec = from.vbPopFrontDouble32Auto();
    rope_length = from.vbPopFrontInt32();
    braking_length = from.vbPopFrontInt32();
    braking_extension_length = from.vbPopFrontInt32();

    slowing_length = from.vbPopFrontInt32();
    slow_erpm = from.vbPopFrontDouble32Auto();
    rewinding_trigger_length = from.vbPopFrontInt32();
    unwinding_trigger_length = from.vbPopFrontInt32();
    pull_current = from.vbPopFrontDouble32Auto();

    pre_pull_k = from.vbPopFrontDouble32Auto();
    takeoff_pull_k = from.vbPopFrontDouble32Auto();
    fast_pull_k = from.vbPopFrontDouble32Auto();
    takeoff_trigger_length = from.vbPopFrontInt32();
    pre_pull_timeout = from.vbPopFrontInt32();

    takeoff_period = from.vbPopFrontInt32();
    brake_current = from.vbPopFrontDouble32Auto();
    slowing_current = from.vbPopFrontDouble32Auto();
    manual_brake_current = from.vbPopFrontDouble32Auto();
    unwinding_current = from.vbPopFrontDouble32Auto();

    rewinding_current = from.vbPopFrontDouble32Auto();
    slow_max_current = from.vbPopFrontDouble32Auto();
    manual_slow_max_current = from.vbPopFrontDouble32Auto();
    manual_slow_speed_up_current = from.vbPopFrontDouble32Auto();
    manual_slow_erpm = from.vbPopFrontDouble32Auto();

    return true;
}

QByteArray QMLable_skypuff_config::serializeV1() const
{
    VByteArray vb;

    vb.vbAppendUint8(SK_COMM_SETTINGS_V1); // Version

    vb.vbAppendUint8(motor_poles);
    vb.vbAppendDouble32Auto(gear_ratio);
    vb.vbAppendDouble32Auto(wheel_diameter);

    vb.vbAppendDouble32Auto(amps_per_kg);
    vb.vbAppendDouble32Auto(amps_per_sec);
    vb.vbAppendInt32(rope_length);
    vb.vbAppendInt32(braking_length);
    vb.vbAppendInt32(braking_extension_length);
    vb.vbAppendInt32(slowing_length);
    vb.vbAppendDouble32Auto(slow_erpm);
    vb.vbAppendInt32(rewinding_trigger_length);
    vb.vbAppendInt32(unwinding_trigger_length);
    vb.vbAppendDouble32Auto(pull_current);
    vb.vbAppendDouble32Auto(pre_pull_k);
    vb.vbAppendDouble32Auto(takeoff_pull_k);
    vb.vbAppendDouble32Auto(fast_pull_k);
    vb.vbAppendInt32(takeoff_trigger_length);
    vb.vbAppendInt32(pre_pull_timeout);
    vb.vbAppendInt32(takeoff_period);
    vb.vbAppendDouble32Auto(brake_current);
    vb.vbAppendDouble32Auto(slowing_current);
    vb.vbAppendDouble32Auto(manual_brake_current);
    vb.vbAppendDouble32Auto(unwinding_current);
    vb.vbAppendDouble32Auto(rewinding_current);
    vb.vbAppendDouble32Auto(slow_max_current);
    vb.vbAppendDouble32Auto(manual_slow_max_current);
    vb.vbAppendDouble32Auto(manual_slow_speed_up_current);
    vb.vbAppendDouble32Auto(manual_slow_erpm);

    return vb;
}
