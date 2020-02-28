import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.12





Item {
    id: batteryBlock
    property var gauge

    width: gauge.diameter / 2.6
    height: gauge.diameter / 11.5

    //anchors.topMargin: gauge.batteryTopMargin
    anchors.horizontalCenter: gauge.horizontalCenter
    anchors.bottom: gauge.bottom

    property real battFontSize: Math.max(10, battery.height * 0.51)
    property real whFontSize: Math.max(10, battery.height * 0.55)
    property real arrowFontSize: Math.max(10, battery.height * 0.5)

    property real margin: 5

    property bool isCharging: false
    property bool isDischarging: false

    Rectangle {
        id: battery
        width: parent.width
        height: parent.height

        border.color: gauge.borderColor
        border.width: 2
        x: gauge.paddingLeft


        radius: 3
        color: gauge.innerColor

        Item {
            id: outWh
            anchors.left: outArrow.left
            anchors.leftMargin: -outWhT.width - batteryBlock.margin
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                id: outWhT
                font.pixelSize: batteryBlock.whFontSize
                text: gauge.getWhValStr(gauge.whOut)
            }
        }

        Item {
            id: outArrow
            anchors.left: parent.left
            anchors.leftMargin: -outArrow.width - batteryBlock.margin
            anchors.verticalCenter: parent.verticalCenter
            width: outArrowT.width


            Text {
                id: outArrowT
                visible: !batteryBlock.isCharging
                font.pixelSize: batteryBlock.arrowFontSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                text: '  >> '
                color: gauge.textColor;
            }

            ProgressBar {
                id: outArrowTProgress
                visible: batteryBlock.isCharging
                width: outArrowT.width
                anchors.verticalCenter: parent.verticalCenter
                indeterminate: true
                contentItem.implicitHeight: 8
                Material.accent: Material.Green

                background: Rectangle {
                    anchors.left: outArrowTProgress.left
                    anchors.verticalCenter: outArrowTProgress.verticalCenter
                    implicitWidth: 50
                    implicitHeight: 20
                    color: "#00000000"
                    radius: 3
                }


                //color:  ? '#4CAF50' : gauge.textColor;
            }
        }

        Rectangle {
            opacity: gauge.baseOpacity
            radius: 2

            anchors.left: battery.left
            anchors.leftMargin: parent.border.width
            anchors.topMargin: parent.border.width
            anchors.verticalCenter: battery.verticalCenter

            property bool battD: gauge.isBatteryBlinking
            property string battDColor: gauge.battDangerColor

            onBattDChanged: {
                battDAnimation.loops = battD ? Animation.Infinite : 1;
                if (!battD) battDColor = gauge.battDangerColor;
            }

            ColorAnimation on battDColor {
                id: battDAnimation
                running: gauge.isBatteryBlinking
                from: gauge.battDangerColor
                to: gauge.battWarningColor
                duration: gauge.gaugesColorAnimation
                loops: Animation.Infinite
            }

            height: battery.height - parent.border.width * 2
            color: gauge.isBatteryWarning || gauge.isBatteryBlinking ? battDColor : gauge.battColor
            width: (battery.width - parent.border.width * 2) * gauge.batteryPercents / 100
        }

        Item {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6

                font.pixelSize: batteryBlock.battFontSize
                id: tBat
                text: qsTr("%1 x %2").arg(gauge.batteryCellVolts.toFixed(2)).arg(gauge.batteryCells)
            }
        }

        Item {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 6
                font.pixelSize: batteryBlock.battFontSize
                id: tBatPercent
                text: gauge.batteryPercents.toFixed(0) + '%'
            }
        }

        Rectangle {
            anchors.left: battery.right
            anchors.verticalCenter: battery.verticalCenter
            color: gauge.borderColor
            height: battery.height * 0.5
            width: 3
            border.color: gauge.borderColor
        }

        Item {
            id: inArrow
            anchors.right: parent.right
            anchors.rightMargin: -inArrow.width - batteryBlock.margin
            anchors.verticalCenter: parent.verticalCenter

            width: inArrowT.width

            Text {
                id: inArrowT
                visible: !batteryBlock.isDischarging
                font.pixelSize: batteryBlock.arrowFontSize
                text: '  >> '
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                color: gauge.textColor
            }

            ProgressBar {
                id: inArrowTProgress
                visible: batteryBlock.isDischarging
                width: inArrowT.width
                anchors.verticalCenter: parent.verticalCenter
                indeterminate: true
                Material.accent: Material.Red

                implicitHeight: 50

                contentItem.implicitHeight: 8

                background: Rectangle {
                    anchors.left: inArrowTProgress.left
                    anchors.verticalCenter: inArrowTProgress.verticalCenter
                    implicitWidth: 50
                    implicitHeight: 20
                    color: "#00000000"
                    radius: 3
                }

                //color:  ? '#4CAF50' : gauge.textColor;
            }
        }

        Item {
            id: inWh
            anchors.right: inArrow.right
            anchors.rightMargin: -inWhT.width - batteryBlock.margin
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                id: inWhT
                font.pixelSize: batteryBlock.whFontSize
                text: gauge.getWhValStr(gauge.whIn)
            }
        }
    }
}
