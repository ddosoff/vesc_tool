import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.3

import SkyPuff.vesc.winch 1.0

Page {
    id: page
    state: "DISCONNECTED"

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
        }

        // Status text with 10 secs cleaner
        Text {
            id: tStatus
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter

            Timer {
                id: statusCleaner
                interval: 10 * 1000 // 10 secs
                running: false
                repeat: false

                onTriggered: {
                    tStatus.text = ""
                }
            }

            Connections {
                target: Skypuff

                onStatusChanged: {
                    tStatus.text = status
                    statusCleaner.restart()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20

            Text {
                Layout.fillWidth: true

                text: isNaN(Skypuff.drawn_meters) ? "" : qsTr("%1m left").arg(Skypuff.left_meters.toFixed(1))

                // 15% - yellow, 5% - red
                color: Skypuff.left_meters / Skypuff.rope_meters < 0.05 ? "red" : Skypuff.left_meters / Skypuff.rope_meters < 0.15 ? "yellow": "green"
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight

                text: isNaN(Skypuff.drawn_meters) ? "" : qsTr("Drawn: %1m").arg(Skypuff.drawn_meters.toFixed(1))
            }
        }

        // RadialBar?
        ProgressBar {
            id: pRopeLeft
            Layout.fillWidth: true

            from: 0
            to: Skypuff.rope_meters

            value: Skypuff.rope_meters - Skypuff.pos_meters
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter

            text: isNaN(Skypuff.drawn_meters) ? "" : qsTr("%1m/s").arg(Skypuff.speed_ms.toFixed(1))

            // above 15ms red, above 10 yellow
            color: Skypuff.speed_ms > 15 ? "red" : Skypuff.speed_ms > 10 ? "yellow" : "green"
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
            Layout.fillHeight: true
        }

        Button {
            id: bSetZero
            text: qsTr("Set zero here")

            Layout.fillWidth: true
            visible: false

            onClicked: {Skypuff.sendTerminal("set_zero")}
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

            onClicked: {Skypuff.sendTerminal("set %1".arg(bUnwinding.state))}
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
        RowLayout {
            id: rManualSlow

            visible: false

            Button {
                text: "←";
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: "→";
            }
        }
    }


    Connections {
        target: Skypuff

        function onExit(state) {
            switch(state) {
            case "MANUAL_BRAKING":
                bStop.enabled = true
                bSetZero.visible = false
                rManualSlow.visible = false
                bPrePull.visible = true
                bPrePull.state = "PRE_PULL"
                break
            case "DISCONNECTED":
                bStop.enabled = true
                bPrePull.enabled = true
                pullForce.enabled = true
                break
            }
        }

        function onEnter(state) {
            switch(state) {
            case "MANUAL_BRAKING":
                bStop.enabled = false
                bSetZero.visible = true
                bUnwinding.state = Skypuff.isBrakingExtensionRange ? "BRAKING_EXTENSION" : "UNWINDING"
                bUnwinding.enabled = true
                bPrePull.visible = false
                rManualSlow.visible = true
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

            /*
            switch(newState) {
            case "DISCONNECTED":
                lState.text = qsTr("Disconnected")

                bStop.enabled = false
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "BRAKING":
                lState.text = qsTr("Braking %1").arg("braking" in params ? params["braking"] : "")

                bStop.enabled = true
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "BRAKING_EXTENSION":
                lState.text = qsTr("Braking ext %1").arg("braking" in params ? params["braking"] : "")

                bStop.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "PRE_PULL"
                break
            case "MANUAL_BRAKING":
                lState.text = qsTr("Manual Braking %1").arg("braking" in params ? params["braking"] : "")

                bStop.enabled = false
                break
            case "UNWINDING":
                lState.text = qsTr("Unwinding %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "PRE_PULL"
                break
            case "REWINDING":
                lState.text = qsTr("Rewinding %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "PRE_PULL"
                break
            case "SLOWING":
                lState.text = qsTr("Slowing %1").arg("speed" in params ? params["speed"] : "")

                bStop.enabled = true
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "SLOW":
                lState.text = qsTr("Slow %1").arg("speed" in params ? params["speed"] : "")

                bStop.enabled = true
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "PRE_PULL":
                lState.text = qsTr("Pre Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "TAKEOFF_PULL"
                break
            case "TAKEOFF_PULL":
                lState.text = qsTr("Takeoff Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "PULL"
                break
            case "PULL":
                lState.text = qsTr("Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "FAST_PULL"
                break
            case "FAST_PULL":
                lState.text = qsTr("Fast Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bPrePull.enabled = false
                bPrePull.state = "FAST_PULL"
                break
            case "UNITIALIZED":
                lState.text = qsTr("No valid settings")

                bStop.enabled = false
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            default:
                // Do not know what to do exactly..
                lState.text = newState
            }
*/

        onSettingsChanged: {
            pullForce.to = cfg.motor_max_kg
            pullForce.stepSize = cfg.motor_max_kg / 30
            pullForce.value = cfg.pull_kg
        }
    }
}
