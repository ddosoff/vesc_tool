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
            enabled: false

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
                id: tRopeLeft
                text: qsTr("Rope left")

                color: "green"
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                id: tDrawnOut
                text: qsTr("Drawn out")

                color: "green"
            }
        }

        // RadialBar?
        ProgressBar {
            id: pRopeLeft
            Layout.fillWidth: true

            from: 0
            to: 100

            value: 100
        }

        Text {
            id: tSpeed
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
                id: bMinusPull

                text: "-"
                enabled: false
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
                id: bPlusPull

                text: "+"
                enabled: false
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Button {
            id: bUnwinding
            text: qsTr("Unwinding")

            Layout.fillWidth: true
            enabled: false

            onClicked: {Skypuff.sendTerminal("set UNWINDING")}

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

    // status cleaner
    Timer {
        id: tStatusCleaner
        interval: 10 * 1000 // 10 secs
        running: false
        repeat: false

        onTriggered: {
            lStatusMessage.text = ""
        }
    }

    Connections {
        target: Skypuff

        onStatusMessage: {
            var t = msg // Original message by default
            var p

            // Translate known MCU messages into UI langugage
            //
            // -- slow pulling too high -1.0Kg (-7.1A) is more 1.0Kg (7.0A)
            if((p = t.match(/pulling too high .?(\d+.\d+)Kg/)))
                t = qsTr("Stopped by pulling %1Kg").arg(p[1])

            // -- Unwinded from slowing zone 4.00m (972 steps)
            else if((p = t.match(/Unwinded from slowing zone .?(\d+.\d+)m/)))
                t = qsTr("%1m slowing zone unwinded").arg(p[1])

            // -- Pre pull 2.0s timeout passed, saving position
            else if((p = t.match(/Pre pull (\d+.\d+)s timeout passed/)))
                t = qsTr("%1s passed, detecting motion").arg(p[1])

            // -- Motion 0.10m (24 steps) detected
            else if((p = t.match(/Motion (\d+.\d+)m/)))
                t = qsTr("%1m motion detected").arg(p[1])

            // -- Takeoff 5.0s timeout passed
            else if((p = t.match(/Takeoff (\d+.\d+)s/)))
                t = qsTr("%1s takeoff, normal pull").arg(p[1])

            lStatusMessage.text = t
            tStatusCleaner.restart()
        }

        onStateChanged: {
            // Really changed?
            if(page.state !== newState) {
                // Exit from?
                switch(page.state) {
                case "MANUAL_BRAKING":
                    bPrePull.visible = true
                    bPrePull.state = "PRE_PULL"
                    rManualSlow.visible = false
                    break
                case "DISCONNECTED":
                    bMinusPull.enabled = true
                    bPlusPull.enabled = true
                    break
                }

                // Entering to?
                switch(newState) {
                case "MANUAL_BRAKING":
                    bPrePull.visible = false
                    rManualSlow.visible = true
                    break
                case "DISCONNECTED":
                    bStop.enabled = false
                    bUnwinding.enabled = false
                    bPrePull.enabled = false
                    bMinusPull.enabled = false
                    bPlusPull.enabled = false
                    break
                }
            }

            switch(newState) {
            case "DISCONNECTED":
                lState.text = qsTr("Disconnected")

                bStop.enabled = false
                bUnwinding.enabled = false
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "BRAKING":
                lState.text = qsTr("Braking %1").arg("braking" in params ? params["braking"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "BRAKING_EXTENSION":
                lState.text = qsTr("Braking ext %1").arg("braking" in params ? params["braking"] : "")

                bStop.enabled = true
                bUnwinding.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "PRE_PULL"
                break
            case "MANUAL_BRAKING":
                lState.text = qsTr("Manual Braking %1").arg("braking" in params ? params["braking"] : "")

                bStop.enabled = false
                bUnwinding.enabled = true
                break
            case "UNWINDING":
                lState.text = qsTr("Unwinding %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = true
                bPrePull.state = "PRE_PULL"
                break
            case "REWINDING":
                lState.text = qsTr("Rewinding %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = true
                bPrePull.state = "PRE_PULL"
                break
            case "SLOWING":
                lState.text = qsTr("Slowing %1").arg("speed" in params ? params["speed"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "SLOW":
                lState.text = qsTr("Slow %1").arg("speed" in params ? params["speed"] : "")

                bStop.enabled = true
                bUnwinding.enabled = false
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            case "PRE_PULL":
                lState.text = qsTr("Pre Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "TAKEOFF_PULL"
                break
            case "TAKEOFF_PULL":
                lState.text = qsTr("Takeoff Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "PULL"
                break
            case "PULL":
                lState.text = qsTr("Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = true
                bPrePull.enabled = true
                bPrePull.state = "FAST_PULL"
                break
            case "FAST_PULL":
                lState.text = qsTr("Fast Pull %1").arg("pull" in params ? params["pull"] : "")

                bStop.enabled = true
                bUnwinding.enabled = true
                bPrePull.enabled = false
                bPrePull.state = "FAST_PULL"
                break
            case "UNITIALIZED":
                lState.text = qsTr("No valid settings")

                bStop.enabled = false
                bUnwinding.enabled = false
                bPrePull.enabled = false
                bPrePull.state = "PRE_PULL"
                break
            default:
                // Do not know what to do exactly..
                lState.text = newState
            }

            page.state = newState
        }

        function updateRope(pos) {
            // Thanks javascript..
            if(typeof pos === 'string')
                pos = parseFloat(pos)

            pRopeLeft.value = pRopeLeft.to - pos

            var tf = pRopeLeft.to > 100 ? 1 : 2
            tRopeLeft.text = qsTr("%1m left").arg(pRopeLeft.value.toFixed(tf))
            tDrawnOut.text = qsTr("Drawn: %1m").arg(pos.toFixed(tf))
        }

        onSettingsChanged: {
            var curPos = pRopeLeft.to - pRopeLeft.value
            pRopeLeft.to = cfg.rope_length_meters
            lPull.text = qsTr("%1Kg").arg(cfg.pull_kg)
            updateRope(curPos)
        }

        onStatsChanged: {
            if("speed" in params)
                tSpeed.text = params["speed"]
            if("pos" in params)
                updateRope(params["pos"])
        }
    }
}
