import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.3

import SkyPuff.vesc.winch 1.0

Page {
    id: page
    state: "DISCONNECTED"

    // Get normal text color from this palette
    SystemPalette {id: systemPalette; colorGroup: SystemPalette.Active}

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Button {
            id: bStop
            text: qsTr("Stop")

            Layout.fillWidth: true
            enabled: false

            onClicked: {Skypuff.sendTerminal("set MANUAL_BRAKING")}
        }

        Label {
            id: lState
            text: Skypuff.stateText

            Layout.fillWidth: true
            Layout.topMargin: 30
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

        // Rope
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20

            Text {
                Layout.fillWidth: true

                text: isNaN(Skypuff.drawnMeters) ? "" : qsTr("Rope: %1 m").arg(Skypuff.leftMeters.toFixed(1))

                // 15% - yellow, 5% - red
                color: Skypuff.leftMeters / Skypuff.ropeMeters < 0.05 ? "red" : Skypuff.leftMeters / Skypuff.ropeMeters < 0.15 ? "yellow": "green"
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight

                text: isNaN(Skypuff.drawnMeters) ? "" : qsTr("Drawn: %1 m").arg(Skypuff.drawnMeters.toFixed(1))
            }
        }

        ProgressBar {
            id: pRopeLeft
            Layout.fillWidth: true

            from: 0
            to: Skypuff.ropeMeters

            value: Skypuff.leftMeters
        }

        // Speed
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 10

            text: isNaN(Skypuff.drawnMeters) ? "" : qsTr("Speed: %1 m/s").arg(Skypuff.speedMs.toFixed(1))

            color: Skypuff.speedMs > 20 ? "red" : systemPalette.text;
        }

        ProgressBar {
            Layout.fillWidth: true

            from: 0
            to: 25

            value: Math.abs(Skypuff.speedMs)
        }

        // Motor
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 10

            text: qsTr("%1: %2 Kg").arg(Skypuff.motorMode).arg(Math.abs(Skypuff.motorKg).toFixed(1))
        }

        ProgressBar {
            id: pbMotor
            Layout.fillWidth: true

            from: 0
            to: 0

            value: Math.abs(Skypuff.motorKg)
        }

        // Power
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 10

            text: qsTr("Power: %1 W").arg(Skypuff.power.toFixed(1))
        }

        ProgressBar {
            id: pbPower
            Layout.fillWidth: true

            from: 0
            to: 0

            value: Math.abs(Skypuff.power)
        }

        // Bat
        RowLayout {
            Layout.topMargin: 20

            Text {
                id: batText
                text: qsTr("Battery %1V").arg(Skypuff.batteryVolts.toFixed(2))
                enabled: Skypuff.isBatteryScaleValid

                color: Skypuff.isBatteryWarning ? "red" : systemPalette.text
                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: Skypuff.isBatteryBlinking
                    ColorAnimation { easing.type: Easing.OutExpo; from: systemPalette.window; to: "red"; duration: 400 }
                    ColorAnimation { easing.type: Easing.OutExpo; from: "red"; to: systemPalette.window;  duration: 200 }

                    onStopped: batText.color = Skypuff.isBatteryWarning ? "red" : systemPalette.text
                }
            }
            ProgressBar {
                Layout.fillWidth: true
                enabled: Skypuff.isBatteryScaleValid
                to: 100
                value: Skypuff.batteryPercents
            }
        }

        // Temps
        RowLayout {
            Layout.topMargin: 20

            Text {
                text: qsTr("T Fets, Mot, Bat: %1, %2, %3").arg(Skypuff.tempFets).arg(Skypuff.tempMotor).arg(Skypuff.tempBat)

                color: Skypuff.tempFets > 80 || Skypuff.tempMotor > 80 ? "red" : systemPalette.text;
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: qsTr("In/out: %1 / %2 Wh").arg(Skypuff.whIn.toFixed(3)).arg(Skypuff.whOut.toFixed(3))
            }
        }

        Item {
            Layout.fillHeight: true
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

        RowLayout {
            id: rManualSlow

            visible: false

            Button {
                text: "←";
                enabled: !Skypuff.isBrakingRange
                onClicked: {Skypuff.sendTerminal("set manual_slow")}
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: "→";
                enabled: !Skypuff.isBrakingRange
                onClicked: {Skypuff.sendTerminal("set manual_slow_back")}
            }
        }
        Button {
            id: bSetZero
            text: qsTr("Set zero here")

            Layout.fillWidth: true
            visible: false

            onClicked: {Skypuff.sendTerminal("set_zero")}
        }
        Button {
            id: bPrePull

            Layout.fillWidth: true
            enabled: false

            state: "PRE_PULL"
            states: [
                State {name: "PRE_PULL"; PropertyChanges {target: bPrePull;text: qsTr("Pre Pull")}},
                State {name: "TAKEOFF_PULL"; PropertyChanges {target: bPrePull;text: qsTr("Takeoff Pull")}},
                State {name: "PULL"; PropertyChanges {target: bPrePull;text: qsTr("Pull")}},
                State {name: "FAST_PULL"; PropertyChanges {target: bPrePull;text: qsTr("Fast Pull")}}
            ]

            onClicked: {Skypuff.sendTerminal("set %1".arg(state))}
        }
        Button {
            id: bUnwinding
            text: qsTr("Unwinding")

            Layout.fillWidth: true
            enabled: false

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


    Connections {
        target: Skypuff

        function onExit(state) {
            switch(state) {
            case "MANUAL_BRAKING":
                bStop.enabled = true

                // Disable MANUAL_BRAKING elemets
                bSetZero.visible = false
                rManualSlow.visible = false

                // Return other states visibles
                bPrePull.visible = true
                bPrePull.state = "PRE_PULL"
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
                bStop.enabled = false

                // Make MANUAL_BRAKING controls visible
                bSetZero.visible = true
                rManualSlow.visible = true

                // Disable normal controls
                bPrePull.visible = false
                bPrePull.state = "PRE_PULL"

                bUnwinding.state = Skypuff.isBrakingExtensionRange ? "BRAKING_EXTENSION" : "UNWINDING"
                bUnwinding.enabled = true
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

            pbMotor.to = cfg.motor_max_kg
            pbPower.to = cfg.power_max
        }
    }
}
