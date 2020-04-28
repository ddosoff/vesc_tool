#include "qmlable_skypuff_types.h"

bool QMLable_skypuff_config::deserializeV1(VByteArray& from)
{
    if(from.length() < 4 * 29 - 2 + 2)
            return false;

    motor_poles = from.vbPopFrontUint8();
    gear_ratio = from.vbPopFrontDouble32Auto();
    wheel_diameter = from.vbPopFrontDouble32Auto();

    amps_per_kg = from.vbPopFrontDouble32Auto();
    pull_applying_period = from.vbPopFrontInt16();
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

    antisex_starting_integral = from.vbPopFrontDouble32Auto();
    antisex_reduce_amps = from.vbPopFrontDouble32Auto();
    antisex_reduce_steps = from.vbPopFrontInt32();
    antisex_reduce_amps_per_step = from.vbPopFrontDouble32Auto();
    antisex_unwinding_gain = from.vbPopFrontDouble16(1e2);
    antisex_gain_speed = from.vbPopFrontDouble16(1);

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
    vb.vbAppendInt16(pull_applying_period);
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
    vb.vbAppendDouble32Auto(antisex_starting_integral);
    vb.vbAppendDouble32Auto(antisex_reduce_amps);
    vb.vbAppendInt32(antisex_reduce_steps);
    vb.vbAppendDouble32Auto(antisex_reduce_amps_per_step);
    vb.vbAppendDouble16(antisex_unwinding_gain, 1e2);
    vb.vbAppendDouble16(antisex_gain_speed, 1);

    return std::move(vb);
}

bool QMLable_skypuff_config::saveV1(QSettings &f) const
{
    f.beginGroup("settings");
    f.setValue("version", 1);
    f.endGroup();

    f.beginGroup("vesc_drive");
    f.setValue("motor_poles", motor_poles);
    f.setValue("gear_ratio", QString::number(gear_ratio, 'f', 6));
    f.setValue("wheel_diameter_mm", wheel_diameter_to_mm());
    f.endGroup();

    f.beginGroup("skypuff_drive");
    f.setValue("amps_per_kg", QString::number(amps_per_kg, 'f', 3));
    f.setValue("pull_applying_period", QString::number(pull_applying_period_to_seconds(), 'f', 1));
    f.setValue("rope_length", QString::number(rope_length_to_meters(), 'f', 1));
    f.endGroup();

    f.beginGroup("braking_zone");
    f.setValue("braking_length", QString::number(braking_length_to_meters(), 'f', 1));
    f.setValue("braking_extension_length", QString::number(braking_extension_length_to_meters(), 'f', 1));
    f.setValue("brake_kg", QString::number(brake_current_to_kg(), 'f', 1));
    f.endGroup();

    f.beginGroup("unwinding");
    f.setValue("unwinding_trigger_length", QString::number(unwinding_trigger_length_to_meters(), 'f', 1));
    f.setValue("unwinding_kg", QString::number(unwinding_current_to_kg(), 'f', 1));
    f.endGroup();

    f.beginGroup("rewinding");
    f.setValue("rewinding_trigger_length", QString::number(rewinding_trigger_length_to_meters(), 'f', 1));
    f.setValue("rewinding_kg", QString::number(rewinding_current_to_kg(), 'f', 1));
    f.endGroup();

    f.beginGroup("slowing");
    f.setValue("slowing_length", QString::number(slowing_length_to_meters(), 'f', 1));
    f.setValue("slowing_kg", QString::number(slowing_current_to_kg(), 'f', 1));
    f.setValue("slow_ms", QString::number(slow_erpm_to_ms(), 'f', 1));
    f.setValue("slow_max_kg", QString::number(slow_max_current_to_kg(), 'f', 1));
    f.endGroup();

    f.beginGroup("winch");
    f.setValue("pull_kg", QString::number(pull_current_to_kg(),'f',1));
    f.setValue("pre_pull_k", pre_pull_k_to_percents());
    f.setValue("takeoff_pull_k", takeoff_pull_k_to_percents());
    f.setValue("fast_pull_k", fast_pull_k_to_percents());
    f.setValue("pre_pull_timeout", QString::number(pre_pull_timeout_to_seconds(), 'f', 1));
    f.setValue("takeoff_trigger_length", QString::number(takeoff_trigger_length_to_meters(), 'f', 1));
    f.setValue("takeoff_period", QString::number(takeoff_period_to_seconds(), 'f', 1));
    f.endGroup();

    f.beginGroup("manual");
    f.setValue("manual_brake_kg", QString::number(manual_brake_current_to_kg(), 'f', 1));
    f.setValue("manual_slow_ms", QString::number(manual_slow_erpm_to_ms(), 'f', 1));
    f.setValue("manual_slow_speed_up_kg", QString::number(manual_slow_speed_up_current_to_kg(), 'f', 1));
    f.setValue("manual_slow_max_kg", QString::number(manual_slow_max_current_to_kg(), 'f', 1));
    f.endGroup();

    f.beginGroup("antisex");
    f.setValue("starting_ms", QString::number(antisex_starting_integral_to_ms(), 'f', 1));
    f.setValue("reduce_kg", QString::number(antisex_reduce_amps_to_kg(), 'f', 1));
    f.setValue("reduce_steps", antisex_reduce_steps);
    f.setValue("reduce_per_step_kg", QString::number(antisex_reduce_amps_per_step_to_kg(), 'f', 1));
    f.setValue("unwinding_gain", antisex_unwinding_gain);
    f.setValue("gain_speed_ms", QString::number(antisex_gain_speed_to_ms(), 'f', 1));
    f.endGroup();

    f.sync();
    return f.status() == QSettings::NoError;
}

bool QMLable_skypuff_config::loadV1(QSettings &f)
{
    f.beginGroup("vesc_drive");
    motor_poles = f.value("motor_poles").toInt();
    gear_ratio = f.value("gear_ratio").toDouble();
    wheel_diameter_from_mm(f.value("wheel_diameter_mm").toInt());
    f.endGroup();

    f.beginGroup("skypuff_drive");
    amps_per_kg = f.value("amps_per_kg").toDouble();
    seconds_to_pull_applying_period(f.value("pull_applying_period").toDouble());
    meters_to_rope_length(f.value("rope_length").toDouble());
    f.endGroup();

    f.beginGroup("braking_zone");
    meters_to_braking_length(f.value("braking_length").toDouble());
    meters_to_braking_extension_length(f.value("braking_extension_length").toDouble());
    kg_to_brake_current( f.value("brake_kg").toDouble());
    f.endGroup();

    f.beginGroup("unwinding");
    meters_to_unwinding_trigger_length(f.value("unwinding_trigger_length").toDouble());
    kg_to_unwinding_current(f.value("unwinding_kg").toDouble());
    f.endGroup();

    f.beginGroup("rewinding");
    meters_to_rewinding_trigger_length(f.value("rewinding_trigger_length").toDouble());
    kg_to_rewinding_current(f.value("rewinding_kg").toDouble());
    f.endGroup();

    f.beginGroup("slowing");
    meters_to_slowing_length(f.value("slowing_length").toDouble());
    kg_to_slowing_current(f.value("slowing_kg").toDouble());
    ms_to_slow_erpm(f.value("slow_ms").toDouble());
    kg_to_slow_max_current(f.value("slow_max_kg").toDouble());
    f.endGroup();

    f.beginGroup("winch");
    kg_to_pull_current(f.value("pull_kg").toDouble());
    percents_to_pre_pull_k(f.value("pre_pull_k").toInt());
    percents_to_takeoff_pull_k(f.value("takeoff_pull_k").toInt());
    percents_to_fast_pull_k(f.value("fast_pull_k").toInt());
    seconds_to_pre_pull_timeout(f.value("pre_pull_timeout").toDouble());
    meters_to_takeoff_trigger_length(f.value("takeoff_trigger_length").toDouble());
    seconds_to_takeoff_period(f.value("takeoff_period").toDouble());
    f.endGroup();

    f.beginGroup("manual");
    kg_to_manual_brake_current(f.value("manual_brake_kg").toDouble());
    ms_to_manual_slow_erpm(f.value("manual_slow_ms").toDouble());
    kg_to_manual_slow_speed_up_current(f.value("manual_slow_speed_up_kg").toDouble());
    kg_to_manual_slow_max_current(f.value("manual_slow_max_kg").toDouble());
    f.endGroup();

    f.beginGroup("antisex");
    ms_to_antisex_starting_integral(f.value("starting_ms").toDouble());
    kg_to_antisex_reduce_amps(f.value("reduce_kg").toDouble());
    antisex_reduce_steps = f.value("reduce_steps").toInt();
    kg_to_antisex_reduce_amps_per_step(f.value("reduce_per_step_kg").toDouble());
    antisex_unwinding_gain = f.value("unwinding_gain").toDouble();
    ms_to_antisex_gain_speed(f.value("gain_speed_ms").toDouble());
    f.endGroup();

    return f.status() == QSettings::NoError;
}
