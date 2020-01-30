import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Vedder.vesc.vescinterface 1.0
import SkyPuff.vesc.winch 1.0

Page {
    // ScrollView without Flickable inside breaks horizontal swiping
    ScrollView {
        anchors.fill: parent

        Flickable {
            id: sv
            anchors.fill: parent
            clip: true
            contentHeight: opts.height

            ColumnLayout {
                id: opts
                // Expand layout if window is bigger
                width: sv.width > implicitWidth ? sv.width : implicitWidth

                GroupBox {
                    title: qsTr("VESC drive settings")
                    Layout.fillWidth: true
                    Layout.margins: 10

                    ColumnLayout {
                        anchors.fill: parent

                        RowLayout {
                            Text {
                                text: qsTr('Motor poles (<a href="help">?</a>)')
                                onLinkActivated: VescIf.emitMessageDialog(qsTr("Number of Motor Poles"),
                                                                          qsTr("Actually number of magnets. Always even.<br/><br/>
                                                                      Could be easily calculated if you enable handbrake (HB) current in the Vesc Tool.
                                                                      Then rotate motor by hand and calculate number of stable positions. And multiply by two."),
                                                                          false, false);
                            }
                            Item {Layout.fillWidth: true}
                            SpinBox {
                                id: motor_poles
                                value: 32
                                from: 2
                                to: 60
                                stepSize: 2
                            }
                        }

                        RowLayout {
                            Text {
                                text: qsTr('Gear ratio (<a href="help">?</a>)')
                                onLinkActivated: VescIf.emitMessageDialog(qsTr("Drive Gear Ratio"),
                                                                          qsTr("Number of motor turns per 1 spool turn."),
                                                                          false, false);
                            }
                            Item {Layout.fillWidth: true}
                            RealSpinBox {
                                id: gear_ratio
                                value: 1
                                from: 0.05
                                to: 20
                                decimals: 6
                                stepSize: 0.000001
                            }
                        }

                        RowLayout {
                            Text {text: qsTr("Spool D (MM)")}
                            Item {Layout.fillWidth: true}
                            SpinBox {
                                id: wheel_diameter_mm
                                editable: true
                                value: 350
                                from: 10
                                to: 2000
                                stepSize: 5
                            }
                        }
                    }
                }

                GroupBox {
                    title: qsTr("SkyPUFF drive")
                    Layout.fillWidth: true
                    Layout.margins: 10

                    ColumnLayout {
                        anchors.fill: parent

                        RowLayout {
                            Text {
                                text: qsTr('A / KG (<a href="help">?</a>)')
                                onLinkActivated: VescIf.emitMessageDialog(qsTr("Drive force coefficient"),
                                                                          qsTr("Number of motor Amps per 1Kg of rope tension."),
                                                                          false, false);
                            }
                            Item {Layout.fillWidth: true}
                            RealSpinBox {
                                id: amps_per_kg
                                from: 0.5
                                to: 30
                                value: 3.333
                                stepSize: 0.1
                                decimals: 3
                            }
                        }
                        RowLayout {
                            Text {
                                text: qsTr('Applying (<a href="help">secs</a>)')
                                onLinkActivated: VescIf.emitMessageDialog(qsTr("Smooth pull speed"),
                                                                          qsTr("Number of seconds to apply default pull tension."),
                                                                          false, false);
                            }
                            Item {Layout.fillWidth: true}
                            RealSpinBox {
                                id: pull_applying_period
                                editable: true
                                from: 0.1
                                to: 10
                                value: 1.5
                                decimals: 1
                                stepSize: 0.1
                            }
                        }
                        RowLayout {
                            Text {text: qsTr("Rope (meters)")}
                            Item {Layout.fillWidth: true}
                            RealSpinBox {
                                id: rope_length
                                editable: true
                                from: 5
                                to: 5000
                                value: 1000
                                stepSize: 10
                                decimals: 1
                            }
                        }
                    }
                }

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
                }
            }
        }
    }

    footer: Button {
        enabled: Skypuff.state !== "DISCONNECTED"
        text: qsTr("Save")

        onClicked: {
            var cfg = Skypuff.emptySettings()

            // This part should be first to update units conversion params
            cfg.motor_poles = motor_poles.value
            cfg.gear_ratio = gear_ratio.value
            cfg.wheel_diameter_mm = wheel_diameter_mm.value
            cfg.amps_per_kg = amps_per_kg.value

            // This part depended on values above
            cfg.pull_applying_seconds = pull_applying_period.value
            cfg.rope_length_meters = rope_length.value
            cfg.braking_length_meters = braking_length.value
            cfg.braking_extension_length_meters = braking_extension_length.value
            cfg.slowing_length_meters = slowing_length.value

            cfg.rewinding_trigger_length_meters = rewinding_trigger_length.value
            cfg.unwinding_trigger_length_meters = unwinding_trigger_length.value
            cfg.takeoff_trigger_length_meters = takeoff_trigger_length.value
            cfg.slow_erpm_ms = slow_erpm.value
            cfg.manual_slow_erpm_ms = manual_slow_erpm.value

            cfg.pull_kg = pull_kg.value
            cfg.brake_kg = brake_kg.value
            cfg.manual_brake_kg = manual_brake_kg.value
            cfg.unwinding_kg = unwinding_kg.value
            cfg.rewinding_kg = rewinding_kg.value

            cfg.slow_max_kg = slow_max_kg.value
            cfg.slowing_kg = slowing_kg.value
            cfg.manual_slow_max_kg = manual_slow_max_kg.value
            cfg.manual_slow_speed_up_kg = manual_slow_speed_up_kg.value
            cfg.pre_pull_k_percents = pre_pull_k.value

            cfg.takeoff_pull_k_percents = takeoff_pull_k.value
            cfg.fast_pull_k_percents = fast_pull_k.value
            cfg.pre_pull_timeout_seconds = pre_pull_timeout.value
            cfg.takeoff_period_seconds = takeoff_period.value

            Skypuff.sendSettings(cfg)
        }
    }

    Connections {
        target: Skypuff

        onSettingsChanged: {
            // DIRTY: do not override nice UI defaults with empty conf
            if(cfg.amps_per_kg < 0.1)
                return

            motor_poles.value = cfg.motor_poles
            gear_ratio.value = cfg.gear_ratio
            wheel_diameter_mm.value = cfg.wheel_diameter_mm
            amps_per_kg.value = cfg.amps_per_kg

            pull_applying_period.value = cfg.pull_applying_seconds
            rope_length.value = cfg.rope_length_meters
            braking_length.value = cfg.braking_length_meters
            braking_extension_length.value = cfg.braking_extension_length_meters
            slowing_length.value = cfg.slowing_length_meters

            rewinding_trigger_length.value = cfg.rewinding_trigger_length_meters
            unwinding_trigger_length.value = cfg.unwinding_trigger_length_meters
            takeoff_trigger_length.value = cfg.takeoff_trigger_length_meters
            slow_erpm.value = cfg.slow_erpm_ms
            manual_slow_erpm.value = cfg.manual_slow_erpm_ms

            pull_kg.value = cfg.pull_kg
            brake_kg.value = cfg.brake_kg
            manual_brake_kg.value = cfg.manual_brake_kg
            unwinding_kg.value = cfg.unwinding_kg
            rewinding_kg.value = cfg.rewinding_kg

            slow_max_kg.value = cfg.slow_max_kg
            slowing_kg.value = cfg.slowing_kg
            manual_slow_max_kg.value = cfg.manual_slow_max_kg
            manual_slow_speed_up_kg.value = cfg.manual_slow_speed_up_kg
            pre_pull_k.value = cfg.pre_pull_k_percents

            takeoff_pull_k.value = cfg.takeoff_pull_k_percents
            fast_pull_k.value = cfg.fast_pull_k_percents
            pre_pull_timeout.value = cfg.pre_pull_timeout_seconds
            takeoff_period.value = cfg.takeoff_period_seconds
        }
    }
}
