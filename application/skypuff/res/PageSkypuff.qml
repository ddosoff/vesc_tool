import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.0

import QtQuick.Controls 1.4

import SkyPuff.vesc.winch 1.0

Page {
    id: page
    state: "DISCONNECTED"

    // Get normal text color from this palette
    SystemPalette {id: systemPalette; colorGroup: SystemPalette.Active}

    ColumnLayout {
        anchors.fill: parent


        BigRoundButton {
            id: bStop
            text: qsTr("Stop")
            Layout.fillWidth: true
            enabled: false

            Material.background: '#EF9A9A'

            onClicked: {Skypuff.sendTerminal("set MANUAL_BRAKING")}
        }

        Label {
            id: lState
            text: Skypuff.stateText

            Layout.fillWidth: true
            Layout.topMargin: 10
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 16
            font.bold: true

            color: page.state === "MANUAL_BRAKING" ? "red" : systemPalette.text;
        }

        // Status messages from skypuff with normal text color
        // or blinking faults
        Text {
            id: tStatus
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter

            SequentialAnimation on color {
                id: faultsBlinker
                loops: Animation.Infinite
                ColorAnimation { easing.type: Easing.OutExpo; from: systemPalette.window; to: "red"; duration: 400 }
                ColorAnimation { easing.type: Easing.OutExpo; from: "red"; to: systemPalette.window;  duration: 200 }
            }

            Timer {
                id: statusCleaner
                interval: 5 * 1000

                onTriggered: {
                    tStatus.text = Skypuff.fault

                    if(Skypuff.fault)
                        faultsBlinker.start()
                    else
                        faultsBlinker.stop()
                }
            }

            Connections {
                target: Skypuff

                onStatusChanged: {
                    tStatus.text = newStatus
                    tStatus.color = isWarning ? "red" : systemPalette.text

                    statusCleaner.restart()
                    faultsBlinker.stop()
                }

                onFaultChanged:  {
                    if(newFault) {
                        tStatus.text = newFault
                        faultsBlinker.start()
                    }
                    else
                        statusCleaner.restart()
                }
            }
        }


        RowLayout {
            Layout.leftMargin: 10
            Layout.topMargin: 10

            SkypuffGauge {
                id: sGauge
                Layout.fillWidth: true
                Layout.preferredHeight: page.width - 20

                maxPower: 5000
                minPower: -2200

                //debug: true
                debugBlink: true

                Connections {
                    target: Skypuff

                    onMotorModeChanged: { sGauge.motorMode = Skypuff.motorMode }
                    onMotorKgChanged: { sGauge.motorKg = Math.abs(Skypuff.motorKg) }
                    onSpeedMsChanged: { sGauge.speedMs = Skypuff.speedMs }
                    onPowerChanged: { sGauge.power = Skypuff.power }

                    onLeftMetersChanged: { sGauge.leftRopeMeters = Skypuff.leftMeters.toFixed(1) }
                    onDrawnMetersChanged: { sGauge.ropeMeters = Skypuff.drawnMeters }
                    onRopeMetersChanged: { sGauge.maxRopeMeters = Skypuff.ropeMeters.toFixed() }

                    // Warning and Blink (bool) | I don't know names of this params
                    //onMotorKgWarningChanged: { sGauge.motorKgWarning = false } // Warning
                    //onMotorKgDangerChanged: { sGauge.motorKgDanger = false } // Blink
                    //onRopeWarningChanged: { sGauge.ropeWarning = false }
                    //onRopeDangerChanged: { sGauge.ropeDanger = false }
                    //onPowerWarningChanged: { sGauge.powerWarning = false }
                    //onPowerDangerChanged: { sGauge.powerDanger = false }
                    //onSpeedWarningChanged: { sGauge.speedWarning = false }
                    //onSpeedDangerChanged: { sGauge.speedDanger = false }

                    onSettingsChanged: {
                        sGauge.maxMotorKg = cfg.motor_max_kg
                        sGauge.maxPower = cfg.power_max
                        sGauge.minPower = cfg.power_min
                    }
                }
            }
        }


        RowLayout {
            Layout.topMargin: 15

            Item {
                Layout.fillWidth: true
            }

            SkypuffBattery {
                id: sBattery
                //Layout.fillWidth: true
                Layout.preferredHeight: page.width / 13
                Layout.preferredWidth: page.width / 3

                Connections {
                    target: Skypuff

                    onIsBatteryBlinkingChanged: { sGauge.isBatteryBlinking = Skypuff.isBatteryBlinking }
                    onIsBatteryWarningChanged: { sGauge.isBatteryWarning = Skypuff.isBatteryWarning }
                    onIsBatteryScaleValidChanged: { sGauge.isBatteryScaleValid = Skypuff.isBatteryScaleValid }

                    onWhInChanged: { sGauge.whIn = Skypuff.whIn }
                    onWhOutChanged: { sGauge.whOut = Skypuff.whOut }
                    onBatteryPercentsChanged: { sGauge.batteryPercents = Skypuff.batteryPercents }
                    onBatteryCellVoltsChanged: { sGauge.batteryCellVolts = Skypuff.batteryCellVolts }

                    onSettingsChanged: {
                        sGauge.batteryCells = cfg.battery_cells
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            id: debug
            visible: false

            Rectangle {
                width: parent.width
                height: parent.height

                Grid {
                    columns: 4
                    anchors.fill: parent
                    spacing: 5

                    Column {
                        spacing: 10

                        Column {
                            spacing: 5

                            Text {
                                text: 'Rope val'
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Slider {
                                id: sliderRope
                                minimumValue: sGauge.minRopeMeters
                                maximumValue: sGauge.maxRopeMeters
                                value: sGauge.ropeMeters

                                onValueChanged: {

                                    sGauge.ropeMeters = value;
                                }
                            }
                        }

                        Column {
                            spacing: 5

                            Text {
                                text: 'Kg val'
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Slider {
                                id: sliderKg
                                minimumValue: sGauge.minMotorKg
                                maximumValue: sGauge.maxMotorKg
                                value: sGauge.motorKg
                                Layout.fillWidth: true

                                onValueChanged: {

                                    sGauge.motorKg = value;
                                }
                            }
                        }

                        Column {
                            spacing: 5

                            Text {
                                text: 'Power val'
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Slider {
                                id: sliderPower
                                minimumValue: sGauge.minPower
                                maximumValue: sGauge.maxPower
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
                                minimumValue: sGauge.minSpeedMs
                                maximumValue: sGauge.maxSpeedMs
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
                                minimumValue: 0
                                maximumValue: 100
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
                                minimumValue: 0.00
                                maximumValue: 15.00
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
                                minimumValue: 0
                                maximumValue: 100
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
                                minimumValue: 0
                                maximumValue: 10000
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
                                minimumValue: 0
                                maximumValue: 10000
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
                                minimumValue: 0
                                maximumValue: 1
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
                                minimumValue: 0
                                maximumValue: 1
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
                                minimumValue: 0
                                maximumValue: 100
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
                                minimumValue: -50
                                maximumValue: 150
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
                                minimumValue: 0
                                maximumValue: 1
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
                                minimumValue: 1
                                maximumValue: 20
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

                                minimumValue: 0
                                maximumValue: 200
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

                                minimumValue: 1
                                maximumValue: 20
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
                                minimumValue: 0
                                maximumValue: 100000
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
                                minimumValue: -100000
                                maximumValue: 0
                                value: sGauge.minPower

                                onValueChanged: {
                                    sGauge.minPower = value;
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }


        // Pull force SpinBox and ManualSlow arrows
        RowLayout {
            function isManualSlowButtonsEnabled() {
                return !Skypuff.isBrakingRange &&
                        ["MANUAL_SLOW_SPEED_UP",
                         "MANUAL_SLOW",
                         "MANUAL_SLOW_BACK_SPEED_UP",
                         "MANUAL_SLOW_BACK"].indexOf(page.state) === -1
            }

            function isManualSlowButtonsVisible() {
                return ["MANUAL_BRAKING",
                        "MANUAL_SLOW_SPEED_UP",
                        "MANUAL_SLOW",
                        "MANUAL_SLOW_BACK_SPEED_UP",
                        "MANUAL_SLOW_BACK"].indexOf(page.state) !== -1
            }

            RoundButton {
                id: rManualSlowBack
                text: "←";
                enabled: parent.isManualSlowButtonsEnabled()
                visible: parent.isManualSlowButtonsVisible()
                onClicked: {Skypuff.sendTerminal("set manual_slow")}
                Material.background: '#A5D6A7'
            }

            Item {
                Layout.fillWidth: true
            }

            RealSpinBox {
                id: pullForce

                //Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                enabled: false
                font.pointSize: 16
                font.bold: true

                decimals: 1
                from: 1
                suffix: qsTr("Kg")

                onValueModified: {Skypuff.sendTerminal("force %1".arg(value))}
            }

            Item {
                Layout.fillWidth: true
            }

            RoundButton {
                id: rManualSlowForward
                text: "→";
                enabled: parent.isManualSlowButtonsEnabled()
                visible: parent.isManualSlowButtonsVisible()
                onClicked: {Skypuff.sendTerminal("set manual_slow_back")}
                Material.background: '#A5D6A7'
            }
        }

        RowLayout {
            BigRoundButton {
                id: bSetZero
                text: qsTr("Set zero here")

                Layout.fillWidth: true
                visible: false
                Material.background: '#A5D6A7'

                onClicked: {Skypuff.sendTerminal("set_zero")}
            }

            BigRoundButton {
                id: bPrePull

                Layout.fillWidth: true
                enabled: false
                Material.background: '#A5D6A7'

                state: "PRE_PULL"
                states: [
                    State {name: "PRE_PULL"; PropertyChanges {target: bPrePull;text: qsTr("Pre Pull")}},
                    State {name: "TAKEOFF_PULL"; PropertyChanges {target: bPrePull;text: qsTr("Takeoff Pull")}},
                    State {name: "PULL"; PropertyChanges {target: bPrePull;text: qsTr("Pull")}},
                    State {name: "FAST_PULL"; PropertyChanges {target: bPrePull;text: qsTr("Fast Pull")}}
                ]

                onClicked: {Skypuff.sendTerminal("set %1".arg(state))}
            }

            BigRoundButton {
                id: bUnwinding
                text: qsTr("Unwinding")

                Layout.fillWidth: true
                enabled: false
                Material.background: '#A5D6A7'

                state: "UNWINDING"
                states: [
                    State {name: "UNWINDING"; PropertyChanges {target: bUnwinding; text: qsTr("Unwinding")}},
                    State {name: "BRAKING_EXTENSION"; PropertyChanges {target: bUnwinding; text: qsTr("Brake")}}
                ]

                onClicked: {
                    Skypuff.sendTerminal("set %1".arg(bUnwinding.state))
                }

                Connections {
                    target: Skypuff

                    onBrakingExtensionRangeChanged: {
                        // Brake if possible
                        switch(Skypuff.state) {
                        case "MANUAL_BRAKING":
                            bUnwinding.state = isBrakingExtensionRange ? "BRAKING_EXTENSION" : "UNWINDING"
                            break
                        case "UNWINDING":
                        case "REWINDING":
                            bUnwinding.enabled = isBrakingExtensionRange
                            break
                        }
                    }
                }
            }
        }
    }


    Connections {
        target: Skypuff

        function set_manual_state_visible() {
            // Make MANUAL_BRAKING controls visible
            bSetZero.visible = true
            rManualSlowForward.visible = true
            rManualSlowBack.visible = true

            // Disable normal controls
            bPrePull.visible = false

            // Go back to UNWINDING or BRAKING_EXTENSION?
            bUnwinding.state = Skypuff.isBrakingExtensionRange ? "BRAKING_EXTENSION" : "UNWINDING"
        }

        function set_manual_state_invisible() {
            // Make MANUAL_BRAKING controls visible
            bSetZero.visible = false
            rManualSlowForward.visible = false
            rManualSlowBack.visible = false

            // Disable normal controls
            bPrePull.visible = true
            bPrePull.state = "PRE_PULL"

            // Go back to UNWINDING or BRAKING_EXTENSION?
            bUnwinding.state = Skypuff.isBrakingExtensionRange ? "BRAKING_EXTENSION" : "UNWINDING"
        }

        function onExit(state) {
            switch(state) {
            case "MANUAL_SLOW_SPEED_UP":
            case "MANUAL_SLOW_BACK_SPEED_UP":
            case "MANUAL_SLOW":
            case "MANUAL_SLOW_BACK":
            case "MANUAL_BRAKING":
                bStop.enabled = true

                set_manual_state_invisible()
                break
            case "REWINDING":
            case "UNWINDING":
                bUnwinding.enabled = true
                bUnwinding.state = "UNWINDING"
                break
            case "BRAKING":
                bPrePull.enabled = true
                break
            case "DISCONNECTED":
                bStop.enabled = true
                bUnwinding.enabled = true
                bPrePull.enabled = true
                pullForce.enabled = true
                break
            case "SLOW":
                bPrePull.enabled = true
                break
            case "FAST_PULL":
                bPrePull.enabled = true
                bPrePull.state = "PRE_PULL"
                break
            }
        }

        function onEnter(state) {
            switch(state) {
            case "MANUAL_BRAKING":
                set_manual_state_visible()
                bStop.enabled = false
                bUnwinding.enabled = true
                bSetZero.enabled = true
                break
            case "MANUAL_SLOW_SPEED_UP":
            case "MANUAL_SLOW_BACK_SPEED_UP":
            case "MANUAL_SLOW":
            case "MANUAL_SLOW_BACK":
                set_manual_state_visible()
                bUnwinding.enabled = false
                bSetZero.enabled = false
                break
            case "BRAKING":
                bUnwinding.enabled = false
                bUnwinding.state = "UNWINDING"
                bPrePull.enabled = false
                break
            case "BRAKING_EXTENSION":
                bUnwinding.enabled = true
                bUnwinding.state = "UNWINDING"
                break
            case "REWINDING":
            case "UNWINDING":
                bUnwinding.enabled = Skypuff.isBrakingExtensionRange
                bUnwinding.state = "BRAKING_EXTENSION"
                bPrePull.state = "PRE_PULL"
                break
            case "SLOWING":
                bUnwinding.enabled = false
                bPrePull.enabled = false
                break
            case "PRE_PULL":
                bPrePull.state = "TAKEOFF_PULL"
                break
            case "TAKEOFF_PULL":
                bPrePull.state = "PULL"
                break
            case "PULL":
                bPrePull.state = "FAST_PULL"
                break
            case "FAST_PULL":
                bPrePull.enabled = false
                break
            case "DISCONNECTED":
                bStop.enabled = false
                bPrePull.enabled = false
                pullForce.enabled = false
                break
            }
        }

        onStateChanged: {
            if(page.state !== newState) {
                onExit(page.state)
                onEnter(newState)
            }

            page.state = newState
        }

        onSettingsChanged: {
            pullForce.to = cfg.motor_max_kg
            pullForce.stepSize = cfg.motor_max_kg / 30
            pullForce.value = cfg.pull_kg
        }
    }
}
