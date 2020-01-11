import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.3

import SkyPuff.vesc.winch 1.0

Page {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Button {
            id: bStop
            text: qsTr("Stop")

            Layout.fillWidth: true

            onClicked: {Skypuff.sendTerminal("set MANUAL_BRAKING")}
        }

        Label {
            id: lState
            text: qsTr("Disconnected")

            Layout.fillWidth: true
            Layout.topMargin: 30
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 16
            font.bold: true
        }

        Text {
            id: lStatusMessage

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20

            Text {
                text: qsTr("Rope left")

                color: "green"
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                id: drawnOut
                text: qsTr("Drawn out")

                color: "green"
            }
        }

        // RadialBar?
        ProgressBar {
            Layout.fillWidth: true

            from: 0
            to: 100

            value: 100
        }

        Text {
            id: speedTxt
            text: qsTr("%1m/s").arg(0)

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: "green"
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "-"
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                id: lPull
                text: qsTr("%1Kg").arg(100)

                font.pointSize: 16
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "+"
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Button {
            id: bUnwinding
            text: qsTr("Unwinding")

            Layout.fillWidth: true

            onClicked: {Skypuff.sendTerminal("set UNWINDING")}

        }
        Button {
            id: bPrePull

            Layout.fillWidth: true
            text: qsTr("Pre Pull")

            state: "PRE_PULL"
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

        onStatusMessage: {
            // Skip some unimportant messages
            // You can see them on terminal page
            if(msg.indexOf("pulling too high") !== -1)
                return

            lStatusMessage.text = msg
        }

        onStateChanged: {
            // Really changed?
            if(page.state !== newState) {
                // Exit from?
                switch(page.state) {
                case "MANUAL_BRAKING":
                    bPrePull.visible = true
                    rManualSlow.visible = false
                    break
                }

                // Entering to?
                switch(newState) {
                case "MANUAL_BRAKING":
                    bPrePull.visible = false
                    rManualSlow.visible = true
                    break
                }
            }

            switch(newState) {
            case "DISCONNECTED":
                lState.text = qsTr("Disconnected")

                bStop.enabled = false
                bUnwinding.enabled = false
                bPrePull.enabled = false
                break
            case "BRAKING":
                lState.text = qsTr("Braking %1").arg(params["braking"] ? params["braking"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = false
                break
            case "BRAKING_EXTENSION":
                lState.text = qsTr("Braking ext %1").arg(params["braking"] ? params["braking"] : "")

                bStop.enabled = true
                bUnwinding.enabled = true
                bPrePull.enabled = true
                break
            case "MANUAL_BRAKING":
                lState.text = qsTr("Manual Braking %1").arg(params["braking"] ? params["braking"] : "")

                bStop.enabled = false
                bUnwinding.enabled = true
                break
            case "UNWINDING":
                lState.text = qsTr("Unwinding %1").arg(params["pull"] ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = true
                break
            case "REWINDING":
                lState.text = qsTr("Rewinding %1").arg(params["pull"] ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = true
                break
            case "SLOWING":
                lState.text = qsTr("Slowing %1").arg(params["speed"] ? params["speed"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = false
                break
            case "SLOW":
                lState.text = qsTr("Slow %1").arg(params["speed"] ? params["speed"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = false
                break
            case "UNITIALIZED":
                lState.text = qsTr("No valid settings")

                bStop.enabled = false
                bUnwinding.enabled = false
                bPrePull.enabled = false
                break
            default:
                // Do not know what to do exactly..
                lState.text = newState
            }

            page.state = newState
        }
    }
}
