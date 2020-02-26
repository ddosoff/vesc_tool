import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.12

// Test Gauge element
GridLayout {
    id: debug

    property var gauge
    property int fontSize: 13
    property int leftMargin: gauge.sideMargin / 2

    width: gauge.diameter

    columns: 2
    columnSpacing: 10
    rowSpacing: -20

    Layout.fillWidth: true

    Label {
        text: 'Rope val'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: sliderRope
        from: gauge.minRopeMeters
        to: gauge.maxRopeMeters
        value: gauge.ropeMeters
        Layout.fillWidth: true

        onValueChanged: {
            gauge.ropeMeters = value;
        }
    }

    Label {
        text: 'KG val'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
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

    Label {
        text: 'Power val'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: sliderPower
        from: gauge.minPower
        to: gauge.maxPower
        value: gauge.power
        Layout.fillWidth: true

        onValueChanged: {
            gauge.power = value;
        }
    }

    Label {
        text: 'Speed val'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: sliderSpeed
        from: gauge.minSpeedMs
        to: gauge.maxSpeedMs
        value: gauge.speedMs
        Layout.fillWidth: true

        onValueChanged: {
            gauge.speedMs = value;
        }
    }

    Label {
        text: 'Temps val'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: -50
        to: 150
        value: 0
        Layout.fillWidth: true

        onValueChanged: {
            gauge.tempBat = value;
            gauge.tempFets = value;
            gauge.tempMotor = value;
        }
    }

    Label {
        text: 'Batt val'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0
        to: 100
        value: gauge.batteryPercents
        Layout.fillWidth: true

        onValueChanged: {
            gauge.batteryPercents = value;
        }
    }

    Label {
        text: 'CellV val'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0.00
        to: 15.00
        value: gauge.batteryCellVolts
        Layout.fillWidth: true

        onValueChanged: {
            gauge.batteryCellVolts = value;
        }
    }

    Label {
        text: 'Cell Count'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0
        to: 100
        value: gauge.batteryCells
        Layout.fillWidth: true

        onValueChanged: {
            gauge.batteryCells = value;
        }
    }

    Label {
        text: 'WH in'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0
        to: 100000
        value: gauge.whIn
        Layout.fillWidth: true

        onValueChanged: {
            gauge.whIn = value;
        }
    }

    Label {
        text: 'WH out'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0
        to: 100000
        value: gauge.whOut
        Layout.fillWidth: true

        onValueChanged: {
            gauge.whOut = value;
        }
    }

    Label {
        text: 'Speed max'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0
        to: 100
        value: gauge.maxSpeedMs
        Layout.fillWidth: true

        onValueChanged: {
            gauge.maxSpeedMs = value;
        }
    }

    Label {
        text: 'KG max'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0
        to: 200
        value: gauge.maxMotorKg
        Layout.fillWidth: true

        onValueChanged: {
            gauge.maxMotorKg = value;
        }
    }

    Label {
        text: 'KG step'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 1
        to: 20
        value: gauge.motorKgLabelStepSize
        Layout.fillWidth: true


        onValueChanged: {
            gauge.motorKgLabelStepSize = value;
        }
    }

    Label {
        text: 'Power max'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 0
        to: 100000
        value: gauge.maxPower
        Layout.fillWidth: true

        onValueChanged: {
            gauge.maxPower = value;
        }
    }

    Label {
        text: 'Power min'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: -100000
        to: 0
        value: gauge.minPower
        Layout.fillWidth: true

        onValueChanged: {
            gauge.minPower = value;
        }
    }

    Label {
        text: 'Power step'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        from: 1
        to: 20
        value: gauge.powerLabelStepSize
        Layout.fillWidth: true

        onValueChanged: {
            gauge.powerLabelStepSize = parseInt(value);
        }
    }

    CheckBox {

        text: qsTr("Warning")
        checked: true
    }
    CheckBox {
        text: qsTr("Danger")
        checked: true
    }


/*
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

    */
}
