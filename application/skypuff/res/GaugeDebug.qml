import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.12

// Test Gauge element
GridLayout {
    id: debug

    property var gauge
    property int fontSize: 13
    property int valFontSize: 12

    property int leftMargin: gauge.sideMargin / 2

    width: gauge.diameter

    columns: 3
    columnSpacing: 0
    rowSpacing: -20

    Layout.fillWidth: true

    function prettyNumber(number, tf = 1) {
        if (!number || !!isNaN(number)) return 0;

        if (Math.abs(number) < 1 && number !== 0 && tf === 1) {
            tf = 2;
        } else if (Number.isInteger(number) && tf === 1) {
            tf = 0;
        }

        return parseFloat(number.toFixed(tf));
    }

    Label {
        text: 'Rope val:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(ropeMeters.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: ropeMeters
        from: gauge.minRopeMeters
        to: gauge.maxRopeMeters
        value: gauge.ropeMeters
        Layout.fillWidth: true

        onValueChanged: {
            gauge.ropeMeters = value;
        }
    }

    Label {
        text: 'KG val:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(motorKg.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: motorKg
        from: gauge.minMotorKg
        to: gauge.maxMotorKg
        value: gauge.motorKg
        Layout.fillWidth: true

        onValueChanged: {
            gauge.motorKg = value;
        }
    }

    Label {
        text: 'Power val:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(power.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: power
        from: gauge.minPower
        to: gauge.maxPower
        value: gauge.power
        Layout.fillWidth: true

        onValueChanged: {
            gauge.power = value;
        }
    }

    Label {
        text: 'Speed val:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(speedMs.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: speedMs
        from: gauge.minSpeedMs
        to: gauge.maxSpeedMs
        value: gauge.speedMs
        Layout.fillWidth: true

        onValueChanged: {
            gauge.speedMs = value;
        }
    }

    Label {
        text: 'Temps val:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(temp.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: temp
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
        text: 'Batt val:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(batteryPercents.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: batteryPercents
        from: 0
        to: 100
        value: gauge.batteryPercents
        Layout.fillWidth: true

        onValueChanged: {
            gauge.batteryPercents = value;
        }
    }

    Label {
        text: 'CellV val:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(batteryCellVolts.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: batteryCellVolts
        from: 0
        to: 15
        value: gauge.batteryCellVolts
        Layout.fillWidth: true

        onValueChanged: {
            gauge.batteryCellVolts = value;
        }
    }

    Label {
        text: 'Cell Count:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(batteryCells.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: batteryCells
        from: 0
        to: 100
        value: gauge.batteryCells
        Layout.fillWidth: true

        onValueChanged: {
            gauge.batteryCells = value;
        }
    }

    Label {
        text: 'WH in:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(whIn.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: whIn
        from: 0
        to: 100000
        value: gauge.whIn
        Layout.fillWidth: true

        onValueChanged: {
            gauge.whIn = value;
        }
    }

    Label {
        text: 'WH out:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(whOut.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: whOut
        from: 0
        to: 100000
        value: gauge.whOut
        Layout.fillWidth: true

        onValueChanged: {
            gauge.whOut = value;
        }
    }

    Label {
        text: 'Speed max:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(maxSpeedMs.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: maxSpeedMs
        from: 0
        to: 100
        value: gauge.maxSpeedMs
        Layout.fillWidth: true

        onValueChanged: {
            gauge.maxSpeedMs = value;
        }
    }

    Label {
        text: 'KG max:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(maxMotorKg.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: maxMotorKg
        from: 0
        to: 200
        value: gauge.maxMotorKg
        Layout.fillWidth: true

        onValueChanged: {
            gauge.maxMotorKg = value;
        }
    }

    Label {
        text: 'KG step:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(motorKgLabelStepSize.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: motorKgLabelStepSize
        from: 0
        to: 50
        value: gauge.motorKgLabelStepSize
        Layout.fillWidth: true

        onValueChanged: {
            gauge.motorKgLabelStepSize = value;
        }
    }

    Label {
        text: 'Power max:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(maxPower.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: maxPower
        from: 0
        to: 20000
        value: gauge.maxPower
        Layout.fillWidth: true
        stepSize: 2000

        onValueChanged: {
            gauge.maxPower = value;
        }
    }

    Label {
        text: 'Power min:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(minPower.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: minPower
        from: -20000
        to: 0
        value: gauge.minPower
        Layout.fillWidth: true
        stepSize: 2000

        onValueChanged: {
            gauge.minPower = value;
        }
    }

    Label {
        text: 'Power step:'
        font.pixelSize: debug.fontSize
        Layout.leftMargin: debug.leftMargin
    }

    Label {
        text: prettyNumber(powerLabelStepSize.value)
        font.pixelSize: debug.valFontSize
        Layout.leftMargin: debug.leftMargin
    }

    Slider {
        id: powerLabelStepSize
        from: 1
        to: 20
        value: gauge.powerLabelStepSize
        Layout.fillWidth: true
        stepSize: 1

        onValueChanged: {
            gauge.powerLabelStepSize = parseInt(value, 10);
        }
    }

    CheckBox {
        text: qsTr("Warn")
        checked: false

        nextCheckState: {
            var value = checkState === Qt.Checked;
            gauge.ropeWarning = value;
            gauge.powerWarning = value;
            gauge.motorKgWarning= value;
            gauge.speedWarning = value;
            gauge.isBatteryWarning = value;
        }
    }
    CheckBox {
        text: qsTr("Dng")
        checked: false

        nextCheckState: {
            var value = checkState === Qt.Checked;
            gauge.ropeDanger = value;
            gauge.powerDanger = value;
            gauge.motorKgDanger = value;
            gauge.speedDanger = value;
            gauge.isBatteryBlinking = value;
        }
    }

}
