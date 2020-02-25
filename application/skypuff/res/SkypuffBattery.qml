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



}
