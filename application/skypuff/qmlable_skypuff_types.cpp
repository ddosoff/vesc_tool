#include "qmlable_skypuff_types.h"

bool QMLable_skypuff_config::deserializeV1(VByteArray& from)
{
    if(from.length() < 4 * 25 - 2)
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

    return std::move(vb);
}

bool QMLable_skypuff_config::saveV1(QSettings &f) const
{
    f.beginGroup("settings");
    f.setValue("version", 1);
    f.endGroup();

    f.beginGroup("vesc_drive");
    f.setValue("motor_poles", motor_poles);
    f.setValue("gear_ratio", (double)gear_ratio);
    f.setValue("wheel_diameter_mm", wheel_diameter_to_mm());
    f.endGroup();

    f.beginGroup("skypuff_drive");
    f.setValue("amps_per_kg", (double)amps_per_kg);
    f.setValue("pull_applying_period", (double)pull_applying_period_to_seconds());
    f.setValue("rope_length", (double)rope_length_to_meters());
    f.endGroup();

    /*
    GroupBox {
        title: qsTr("Braking zone")
        Layout.fillWidth: true
        Layout.margins: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Text {text: qsTr("Braking (meters)")}
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: braking_length
                    editable: true
                    from: 1
                    to: 100
                    value: 15
                    stepSize: 1
                    decimals: 1
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Extension (<a href="help">meters</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Braking extension length"),
                                                              qsTr("Set this distance about 150 meters if you use winch in passive mode.<br/><br/>
                                                                Skypuff will extend braking zone. Useful when car is driving
                                                                from pilot to start position.<br/><br/>
                                                                Set big value (5000m) to stop automatic unwinding mode."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: braking_extension_length
                    editable: true
                    from: 0.2
                    to: 5000
                    stepSize: 10
                }
            }
            RowLayout {
                Text {text: qsTr("Braking (KG)")}
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: brake_kg
                    from: 0.2
                    to: 200 // High force possible, no special mode yet
                    value: 1
                    decimals: 1
                    stepSize: 0.2
                }
            }
        }
    }

    GroupBox {
        title: qsTr("Unwinding")
        Layout.fillWidth: true
        Layout.margins: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Text {
                    text: qsTr('Trigger (<a href="help">meters</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Unwinding trigger length"),
                                                              qsTr("The distance to switch on unwinding mode from rewinding in case rope is unwinded from takeoff.<br/><br/>
                                                                Set this not too long."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: unwinding_trigger_length
                    value: 0.8
                    from: 0.1
                    to: 10
                    decimals: 1
                    stepSize: 0.1
                }
            }
            RowLayout {
                Text {text: qsTr("Tension (KG)")}
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: unwinding_kg
                    value: 3
                    from: 0.2
                    to: 20
                    decimals: 1
                    stepSize: 0.2
                }
            }
        }
    }

    GroupBox {
        title: qsTr("Rewinding")
        Layout.fillWidth: true
        Layout.margins: 10

        ColumnLayout {
            anchors.fill: parent
            RowLayout {
                Text {
                    text: qsTr('Trigger (<a href="help">meters</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Rewinding trigger length"),
                                                              qsTr("The distance to switch on rewinding mode from unwinding in case rope is winded to takeoff."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: rewinding_trigger_length
                    value: 20
                    from: 0.5
                    to: 50
                    decimals: 1
                }
            }
            RowLayout {
                Text {text: qsTr("Tension (KG)")}
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: rewinding_kg
                    from: 0.2
                    to: 40
                    value: 5
                    decimals: 1
                    stepSize: 0.2
                }
            }
        }
    }

    GroupBox {
        title: qsTr("Slowing")
        Layout.fillWidth: true
        Layout.margins: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Text {text: qsTr("Length (meters)")}
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: slowing_length
                    editable: true
                    from: 1
                    to: 100
                    decimals: 1
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Braking (<a href="help">KG</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Slowing zone braking force"),
                                                              qsTr("Do not set this too high to prevent rope tangling."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: slowing_kg
                    from: 0
                    to: 10
                    value: 0.1
                    decimals: 1
                    stepSize: 0.1
                }
            }
            RowLayout {
                Text {text: qsTr("Speed (M/S)")}
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: slow_erpm
                    from: 0.5
                    to: 5
                    decimals: 1
                    stepSize: 0.2
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Max (<a href="help">KG</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Maximum tension"),
                                                              qsTr("Tension to exit from slow mode."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: slow_max_kg
                    from: 0.2
                    to: 20
                    value: 5
                    decimals: 1
                    stepSize: 0.2
                }
            }
        }
    }

    GroupBox {
        title: qsTr("Winch settings")
        Layout.fillWidth: true
        Layout.margins: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Text {
                    text: qsTr('Pull (<a href="help">KG</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Default pull force"),
                                                              qsTr("Usually 3/4 of the pilot weight.<br/><br/>
                                                                This parameter could be changed before and during pull modes from the winch controll screen."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: pull_kg
                    from: 0.1
                    to: 600
                    value: 100
                    decimals: 1
                    stepSize: 5
                }
            }
            RowLayout {
                Text {text: qsTr("Pre pull (%)")}
                Item {Layout.fillWidth: true}
                SpinBox {
                    id: pre_pull_k
                    editable: true
                    value: 25
                    from: 10
                    to: 50
                }
            }
            RowLayout {
                Text {text: qsTr("Takeoff (%)")}
                Item {Layout.fillWidth: true}
                SpinBox {
                    id: takeoff_pull_k
                    editable: true
                    value: 50
                    from: 30
                    to: 80
                }
            }
            RowLayout {
                Text {text: qsTr("Fast (%)")}
                Item {Layout.fillWidth: true}
                SpinBox {
                    id: fast_pull_k
                    editable: true
                    value: 125
                    from: 105
                    to: 150
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Timeout (<a href="help">secs</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Pre pull timeout"),
                                                              qsTr("Wait this number of seconds after pre pull, then start detecting motion."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: pre_pull_timeout
                    from: 0.1
                    to: 5
                    value: 2
                    decimals: 1
                    stepSize: 0.2
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Takeoff (<a href="help">meters</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Takeoff trigger distance"),
                                                              qsTr("After pre pull timeout is passed skypuff will detect motion. In case of motion more then this distance takeoff pull will be applied."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: takeoff_trigger_length
                    from: 0.1
                    to: 5000
                    value: 2
                    decimals: 1
                    stepSize: 0.2
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Takeoff (<a href="help">secs</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Takeoff period"),
                                                              qsTr("Number of seconds for takeoff pull."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: takeoff_period
                    from: 0.1
                    to: 60
                    value: 10
                    decimals: 1
                    stepSize: 0.5
                }
            }

        }
    }
    GroupBox {
        title: qsTr("Manual modes")
        Layout.fillWidth: true
        Layout.margins: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Text {
                    text: qsTr('Braking (<a href="help">KG</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Manual braking force"),
                                                              qsTr("Brake force to apply in the manual braking mode."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: manual_brake_kg
                    from: 0.2
                    to: 10
                    value: 3
                    decimals: 1
                    stepSize: 0.2
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Speed (<a href="help">M/S</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Manual slow speed"),
                                                              qsTr("Constant speed to unwind or wind to zero."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: manual_slow_erpm
                    from: 0.5
                    to: 12
                    value: 6
                    decimals: 1
                    stepSize: 0.2
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Speed up (<a href="help">KG</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Speed up force"),
                                                              qsTr("Force to speed up from manual braking until manual constant speed is reached."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: manual_slow_speed_up_kg
                    from: 0.2
                    to: 20
                    value: 2
                    decimals: 1
                    stepSize: 0.2
                }
            }
            RowLayout {
                Text {
                    text: qsTr('Max (<a href="help">KG</a>)')
                    onLinkActivated: VescIf.emitMessageDialog(qsTr("Maximum tension"),
                                                              qsTr("Tension to exit from manual constant speed modes."),
                                                              false, false);
                }
                Item {Layout.fillWidth: true}
                RealSpinBox {
                    id: manual_slow_max_kg
                    from: 0.2
                    to: 20
                    value: 5
                    decimals: 1
                    stepSize: 0.2
                }
            }
        }
        */

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

    return f.status() == QSettings::NoError;
}
