import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.12

// Test Gauge element
ColumnLayout {
    id: debug
    property var gauge

    RowLayout {
        Layout.fillWidth: true
        spacing: 5

        Text {
            text: 'Rope val'
        }

        Slider {
            id: sliderRope
            from: gauge.minRopeMeters
            to: gauge.maxRopeMeters
            value: gauge.ropeMeters

            onValueChanged: {
                gauge.ropeMeters = value;
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 5

        Text {
            text: 'Kg val'
        }

        Slider {
            id: sliderKg
            from: gauge.minMotorKg
            to: gauge.maxMotorKg
            value: gauge.motorKg
            Layout.fillWidth: true

            onValueChanged: {

                gauge.motorKg = value;
            }
        }
    }

/*
            Column {
                spacing: 5


            }

            Column {
                spacing: 5

                Text {
                    text: 'Power val'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    id: sliderPower
                    from: sGauge.minPower
                    to: sGauge.maxPower
                    value: sGauge.power

                    onValueChanged: {
                        sGauge.power = value;
                    }
                }
            }

            Column {
                spacing: 5

                Text {
                    text: 'Speed val'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    id: sliderSpeed
                    from: sGauge.minSpeedMs
                    to: sGauge.maxSpeedMs
                    value: sGauge.speedMs

                    onValueChanged: {
                        sGauge.speedMs = value;
                    }
                }
            }
        }

        Column {
            spacing: 10

            Column {
                spacing: 5

                Text {
                    text: 'Batt val'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 100
                    value: sBattery.batteryPercents

                    onValueChanged: {
                        sBattery.batteryPercents = value;
                    }
                }
            }

            Column {
                spacing: 5

                Text {
                    text: 'CellV val'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0.00
                    to: 15.00
                    value: sBattery.batteryCellVolts

                    onValueChanged: {
                        sBattery.batteryCellVolts = value;
                    }
                }
            }

            Column {
                spacing: 5

                Text {
                    text: 'Cell Count'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 100
                    value: sBattery.batteryCells

                    onValueChanged: {
                        sBattery.batteryCells = value;
                    }
                }
            }

            Column {
                spacing: 5

                Text {
                    text: 'WH in'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 10000
                    value: sBattery.whIn

                    onValueChanged: {
                        sBattery.whIn = value;
                    }
                }
            }

            Column {
                spacing: 5

                Text {
                    text: 'WH out'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 10000
                    value: sBattery.whOut

                    onValueChanged: {
                        sBattery.whOut = value;
                    }
                }
            }
        }

        Column {
            spacing: 10

            Column {
                spacing: 5

                Text {
                    text: 'Warning Gauges'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 1
                    stepSize: 1
                    value: 0

                    onValueChanged: {
                        sGauge.ropeWarning = !!value;
                        sGauge.powerWarning = !!value;
                        sGauge.motorKgWarning= !!value;
                        sGauge.speedWarning = !!value;
                        sBattery.isBatteryWarning = !!value
                    }
                }
            }

            Column {
                spacing: 5

                Text {
                    text: 'Blink Gauges'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 1
                    stepSize: 1
                    value: 0

                    onValueChanged: {
                        sGauge.ropeDanger = !!value;
                        sGauge.powerDanger = !!value;
                        sGauge.motorKgDanger = !!value;
                        sGauge.speedDanger = !!value;
                        sBattery.isBatteryBlinking = !!value
                    }
                }
            }

            Column {
                Text {
                    text: 'Speed max'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 100
                    value: sGauge.maxSpeedMs

                    onValueChanged: {
                        sGauge.maxSpeedMs = value;
                    }
                }
            }

            Column {
                Text {
                    text: 'Temps'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: -50
                    to: 150
                    value: 0

                    onValueChanged: {
                        sGauge.tempBat = value;
                        sGauge.tempFets = value;
                        sGauge.tempMotor = value;
                    }
                }
            }

            Column {
                Text {
                    text: 'Debug'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 1
                    value: 1

                    onValueChanged: {
                        debug.visible = !!value;
                    }
                }
            }
        }

        Column {
            spacing: 10

            Column {
                Text {
                    text: 'Kg step'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 1
                    to: 20
                    value: sGauge.motorKgLabelStepSize

                    onValueChanged: {
                        sGauge.motorKgLabelStepSize = value;
                    }
                }
            }


            Column {
                spacing: 10

                Text {
                    text: 'MaxKg'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {

                    from: 0
                    to: 200
                    value: sGauge.maxMotorKg

                    onValueChanged: {
                        sGauge.maxMotorKg = value;
                    }
                }
            }

            Column {

                Text {
                    text: 'Power step'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {

                    from: 1
                    to: 20
                    value: sGauge.powerLabelStepSize

                    onValueChanged: {
                        sGauge.powerLabelStepSize = parseInt(value);
                    }
                }
            }

            Column {
                Text {
                    text: 'Power max'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: 0
                    to: 100000
                    value: sGauge.maxPower

                    onValueChanged: {
                        sGauge.maxPower = value;
                    }
                }
            }
            Column {
                Text {
                    text: 'Power min'
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Slider {
                    from: -100000
                    to: 0
                    value: sGauge.minPower

                    onValueChanged: {
                        sGauge.minPower = value;
                    }
                }
            }
        }
    }
    */
}
