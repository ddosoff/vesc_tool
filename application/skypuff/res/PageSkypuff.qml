import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.0

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







        GridLayout {

            rowSpacing: 5
            columnSpacing: 5

            width: parent.width

            //flow:  width > height ? GridLayout.LeftToRight : GridLayout.TopToBottom
            flow: GridLayout.LeftToRight

            /*Rectangle {
                anchors.fill: parent
                color: 'blue'
            }*/

            SkypuffGauge {
                id: sGauge

                debug: false
                maxSpeedMs: 10
                Layout.fillWidth: true

                Layout.preferredHeight: page.width * 0.8


                Connections {
                    target: Skypuff

                    onMotorModeChanged: { sGauge.motorMode = Skypuff.motorMode }
                    onMotorKgChanged: { sGauge.motorKg = Math.abs(Skypuff.motorKg) }
                    onSpeedMsChanged: { sGauge.speedMs = Skypuff.speedMs }
                    onPowerChanged: { sGauge.power = Skypuff.power }
                    onLeftMetersChanged: { sGauge.leftRopeMeters = Skypuff.leftMeters.toFixed(1) }
                    onDrawnMetersChanged: { sGauge.ropeMeters = Skypuff.drawnMeters }
                    onRopeMetersChanged: { sGauge.maxRopeMeters = Skypuff.ropeMeters.toFixed() }

                    onSettingsChanged: {
                        sGauge.maxMotorKg = cfg.motor_max_kg
                    }
                }
            }




            ColumnLayout {

                id: mainBarTemp

                RowLayout {
                    Item {
                        width: 18
                        height: 25
                        Image {

                            id: tfetsIco
                            smooth: true

                            source: "qrc:/res/icons/motor.svg"

                            sourceSize.width: 20
                            sourceSize.height: 27

                            visible: false

                        }
                        ColorOverlay {
                            anchors.fill: tfetsIco
                            source: tfetsIco
                            color: Material.color(Material.Blue)
                        }
                    }

                    Item {
                        width: 50
                        height: 25

                        Text {
                            text: Skypuff.tempMotor.toFixed(1) + 'C'
                            color: Skypuff.tempMotor > 80 ? "red" : systemPalette.text;
                        }
                    }
                }

                RowLayout {
                    Item {
                        width: 20
                        height: 25
                        Image {
                            id: tmotIco
                            smooth: true

                            source: "qrc:/res/icons/mcu1.svg"

                            sourceSize.width: 20
                            sourceSize.height: 18

                            visible: false

                        }
                        ColorOverlay {
                            anchors.fill: tmotIco
                            source: tmotIco
                            color: Material.color(Material.Blue)
                        }
                    }

                    Item {
                        width: 50
                        height: 25
                        Text {
                            text: Skypuff.tempFets.toFixed(1) + 'C'
                            color: Skypuff.tempFets > 80 ? "red" : systemPalette.text;
                        }
                    }
                }

                RowLayout {
                    Item {
                        width: 20
                        height: 25
                        Image {
                            id: tbatIco
                            smooth: true

                            source: "qrc:/res/icons/battery.svg"

                            sourceSize.width: 20
                            sourceSize.height: 19

                            visible: false

                        }
                        ColorOverlay {
                            anchors.fill: tbatIco
                            source: tbatIco
                            color: Material.color(Material.Blue)
                        }
                    }

                    Item {
                        width: 50
                        height: 25
                        Text {
                            text: Skypuff.tempBat.toFixed(1) + 'C'
                            color: Skypuff.tempBat > 80 ? "red" : systemPalette.text;
                        }
                    }
                }



            }

        }
        RowLayout {
            width: page.width
            Layout.topMargin: 20

            Item {
                Layout.fillWidth: true
            }

            Text {
                Layout.topMargin: 2
                //width: 40
                text: qsTr("%1/%2").arg(Skypuff.whIn.toFixed(1)).arg(Skypuff.whOut.toFixed(1))
                color: systemPalette.text;
            }


            Text {
                ///width: 40
                font.bold: true
                text: '<<'
                color: 'red';
            }

            Rectangle {
                id: lol
                width: 50
                height: 20
                border.color: 'red'


                ProgressBar {
                    width: parent.width
                    height: parent.height

                    Layout.fillWidth: true
                    enabled: Skypuff.isBatteryScaleValid
                    to: 100
                    value: Skypuff.batteryPercents

                    background: Rectangle {
                        radius: 2
                        color: "lightgray"
                        border.color: "gray"
                        border.width: 1
                        implicitWidth: parent.width
                        implicitHeight: parent.height
                    }

                }
            }

            Text {
                Layout.topMargin: 2
                //width: 40
                text: Skypuff.batteryPercents.toFixed(1) + '%'
                color: systemPalette.text;
            }
            Item {
                Layout.fillWidth: true
            }

        }


        /*RowLayout {
            Layout.topMargin: 20

            Text {
                id: batText
                text: qsTr("Battery %1V (%2V / cell)").arg(Skypuff.batteryVolts.toFixed(2)).arg(Skypuff.batteryCellVolts.toFixed(2))
                enabled: Skypuff.isBatteryScaleValid

                function getBatColor() {return Skypuff.isBatteryScaleValid ? Skypuff.isBatteryWarning ? "red" : "green" : systemPalette.text}

                color: getBatColor()

                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: Skypuff.isBatteryBlinking
                    ColorAnimation { easing.type: Easing.OutExpo; from: systemPalette.window; to: "red"; duration: 400 }
                    ColorAnimation { easing.type: Easing.OutExpo; from: "red"; to: systemPalette.window;  duration: 200 }

                    onStopped: batText.color = getBatColor()
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
                text: qsTr("Temps: %1, %2, %3").arg(Skypuff.tempFets).arg(Skypuff.tempMotor).arg(Skypuff.tempBat)

                color: Skypuff.tempFets > 80 || Skypuff.tempMotor > 80 ? "red" : systemPalette.text;
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: qsTr("In/out: %1 / %2 Wh").arg(Skypuff.whIn.toFixed(3)).arg(Skypuff.whOut.toFixed(3))
            }
        }*/

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
