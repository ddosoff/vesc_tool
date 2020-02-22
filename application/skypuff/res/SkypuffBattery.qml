import QtQuick 2.0

Rectangle {
    id: root
    enabled: root.isBatteryScaleValid

    property int diameter: width < height ? width : height

    property real batteryPercents: 0
    property real batteryCellVolts: 0.0
    property int batteryCells: 0
    property real whIn: 0.0
    property real whOut: 0.0

    property bool isBatteryBlinking: false
    property bool isBatteryWarning: false
    property bool isBatteryScaleValid: false

    property real baseOpacity: 0.5  // Opacity is to all colors of the scale
    property string battGaugeColor: '#dbdee3'
    property string borderColor: '#515151'

    // Default for all scales
    property string defaultColor: '#4CAF50' // base color (green)
    property string dangerColor: 'red'      // attention color (red)
    property string warningColor: '#dbdee3' // blink color (yellow)

    property int gaugesColorAnimation: 1000  // freq of blinking


    // Battery
    property string battColor: root.defaultColor
    property string battWarningColor: root.warningColor
    property string battDangerColor: root.dangerColor

    function prettyNumber(number, tf = 1) {
        if (!number || !!isNaN(number)) return 0;

        if (Math.abs(number) < 1 && number !== 0 && tf === 1) {
            tf = 2;
        } else if (Number.isInteger(number) && tf === 1) {
            tf = 0;
        }

        return parseFloat(number.toFixed(tf));
    }


    function getWhValStr(val) {
        if (val >= 1000) {
            return prettyNumber(val / 1000) + ' kWh';
        }

        return prettyNumber(val) + ' Wh';
    }

    Rectangle {
        id: batBlock
        width: root.width
        height: root.height
        border.color: root.borderColor
        border.width: 2

        radius: 3
        color: root.battGaugeColor

        Item {
            id: inWh
            anchors.left: inArrow.left
            anchors.leftMargin: -inWhT.width - 10
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                id: inWhT
                font.pixelSize: Math.max(10, root.diameter * 0.6)
                text: root.getWhValStr(root.whIn)
            }
        }


        Item {
            id: inArrow
            anchors.left: parent.left
            anchors.leftMargin: -inArrow.width - 10
            anchors.verticalCenter: parent.verticalCenter
            width: inArrowT.width

            Text {
                id: inArrowT
                font.pixelSize: Math.max(10, root.diameter * 0.6)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                text: '>>'
                color: 'red';
            }
        }

        Rectangle {
            opacity: root.baseOpacity
            radius: 2

            anchors.left: batBlock.left
            anchors.leftMargin: parent.border.width
            anchors.topMargin: parent.border.width
            anchors.verticalCenter: batBlock.verticalCenter

            property bool battD: root.isBatteryBlinking
            property string battDColor: root.battDangerColor

            onBattDChanged: {
                battDAnimation.loops = battD ? Animation.Infinite : 1;
                if (!battD) battDColor = root.battDangerColor;
            }

            ColorAnimation on battDColor {
                id: battDAnimation
                running: root.isBatteryBlinking
                from: root.battDangerColor
                to: root.battWarningColor
                duration: root.gaugesColorAnimation
                loops: Animation.Infinite
            }

            height: batBlock.height - parent.border.width * 2
            color: root.isBatteryWarning || root.isBatteryBlinking ? battDColor : root.battColor
            width: (batBlock.width - parent.border.width * 2) * root.batteryPercents / 100
        }

        Item {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6

                font.pixelSize: Math.max(10, root.diameter * 0.5)
                id: tBat
                text: qsTr("%1 x %2").arg(root.batteryCellVolts.toFixed(2)).arg(root.batteryCells)
            }
        }

        Item {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 6
                font.pixelSize: Math.max(10, root.diameter * 0.5)
                id: tBatPercent
                text: root.batteryPercents.toFixed(0) + '%'
            }
        }

        Rectangle {
            anchors.left: batBlock.right
            anchors.verticalCenter: batBlock.verticalCenter
            color: root.borderColor
            height: root.diameter * 0.5
            width: 3
            border.color: root.borderColor
        }

        Item {
            id: outArrow


            anchors.right: parent.right
            anchors.rightMargin: -outArrow.width - 10
            anchors.verticalCenter: parent.verticalCenter

            width: outArrowT.width

            Text {
                id: outArrowT
                font.pixelSize: Math.max(10, root.diameter * 0.6)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                text: '>>'
                color: 'red';
            }
        }

        Item {
            id: outWh
            anchors.right: outArrow.right
            anchors.rightMargin: -outWhT.width - 10
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                id: outWhT
                font.pixelSize: Math.max(10, root.diameter * 0.6)
                text: root.getWhValStr(root.whOut)
            }
        }
    }
}
