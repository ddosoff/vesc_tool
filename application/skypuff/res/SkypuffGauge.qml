import QtQuick 2.12
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4

import QtQml 2.2

import QtQuick.Controls.Material 2.12


import QtGraphicalEffects 1.0;
import QtQuick.Layouts 1.1



Item {
    id:root
    SystemPalette {id: systemPalette; colorGroup: SystemPalette.Active}

    property real speedMs: 0
    property real maxSpeedMs: 30
    property real minSpeedMs: maxSpeedMs * -1

    property real ropeMeters: 0
    property real leftRopeMeters: maxRopeMeters - ropeMeters
    property real minRopeMeters: 0
    property real maxRopeMeters: 800

    property real power: 0
    property real maxPower: 20
    property real minPower: maxPower * -1

    property real motorKg
    property real minMotorKg: 0
    property real maxMotorKg: 15

    property real tempFets: 0
    property real tempMotor: 0
    property real tempBat: 0

    property real whIn: 0
    property real whOut: 0

    property string motorMode: 'Not Connected'

    /********************
            Colors
    ********************/

    property real baseOpacity: 0.4  // Opacity is superimposed on all colors of the scale.
    property string innerColor: '#efeded'
    property string gaugeDangerFontColor: '#8e1616' // Color of danger ranges
    property string gaugeFontColor: '#515151'
    property string gaugeColor: '#C7CFD9'

    // Default for all scales
    property string warningColor: '#FF5722'
    property string dangerColor: 'red'
    property real warningColorPercent: 0.70
    property real dangerColorPercent: 0.85

    // Rope
    property string ropeColor: '#9C27B0'
    property string ropeWarningColor: root.warningColor
    property string ropeDangerColor: root.dangerColor
    property real ropeWarningColorPercent: root.warningColorPercent
    property real ropeDangerColorPercent: root.dangerColorPercent

    // MotorKg
    property string motorKgColor: '#3F51B5'
    property string motorKgWarningColor: root.warningColor
    property string motorKgDangerColor: root.dangerColor
    property real motorKgWarningColorPercent: root.warningColorPercent
    property real motorKgDangerColorPercent: root.dangerColorPercent

    // Power
    property string powerColor: '#009688'
    property string powerWarningColor: root.warningColor
    property string powerDangerColor: root.dangerColor
    property real powerWarningColorPercent: root.warningColorPercent
    property real powerDangerColorPercent: root.dangerColorPercent

    // Speed
    property string speedColor: '#2196F3'
    property string speedWarningColor: root.warningColor
    property string speedDangerColor: root.dangerColor
    property real speedWarningColorPercent: root.warningColorPercent
    property real speedDangerColorPercent: root.dangerColorPercent

    /********************
        Default view
    ********************/
    property int diameter: parent.width > parent.height
       ? parent.height
       : parent.width

    property string borderColor: '#515151'      // Color of all borders
    property string color: '#efeded'            // Main backgroundColor
    property int diagLAnc: 55                   // Angle of diagonal lines from 12 hours
    property string ff: 'Roboto'                // Font family

    /********************
            Gauge
    ********************/
    property real gaugeHeight: diameter * 0.09;
    property bool boldValues: false
    property bool enableAnimation: true
    property int animationDuration: 100
    property int animationType: Easing.OutExpo

    property real motorKgLabelStepSize: (maxMotorKg - minMotorKg) / 5
    property real powerLabelStepSize: (maxPower - minPower) / 4

    /********************
         Do not touch
    ********************/
    property bool debug: false
    property int angK: 1000


    function prettyNumber(number, tf = 1) {
        // TODO: need to check this number
        if (!number || !!isNaN(number)) return 0;

        if (Math.abs(number) < 1 && number !== 0 && tf === 1) {
            tf = 2;
        }

        return number.toFixed(tf);
    }

    /**
      Convert rope's value to angl
      180 - (125 - 55) = 110. Working range with default diagLAnc
    */
    function ropeToAng(value) {
        value = value * root.angK
        // If the scale starts with a negative value
        var deltaForNegativeMinRope = root.minRopeMeters < 0 ? Math.abs(root.minRopeMeters) : 0;

        // If the scale starts with a positive value
        var deltaForPositiveMinRope = root.minRopeMeters > 0 ? -1 * root.minRopeMeters : 0;

        // Working range of top bar
        var diapAng = 180 - (dl2.rotation - dl1.rotation) ;

        // Range of rope
        var diapRope = (root.maxRopeMeters - root.minRopeMeters) * root.angK;
        var delta = diapAng / diapRope;

        var res = (value + deltaForNegativeMinRope + deltaForPositiveMinRope) * delta;

        // 0.1 - is a little fix for canvas context.arc
        return (value === minRopeMeters ? res + 0.1 : res)  - dl1.rotation;
    }

    /**
      Convert speed's value to angl
    */
    function speedToAng(value) {
        var deltaForNegativeMinSpeed = root.minSpeedMs < 0 ? Math.abs(root.minSpeedMs) : 0;
        var deltaForPositiveMinSpeed = root.minSpeedMs > 0 ? -1 * root.minSpeedMs : 0;

        // Working range of bottom bar
        var diapAng = 180 - (dl2.rotation - dl1.rotation);

        // Range of speed
        var diapSpeed = root.maxSpeedMs - root.minSpeedMs;
        var delta = diapAng / diapSpeed;

        return (dl2.rotation + diapAng) - (value + deltaForNegativeMinSpeed + deltaForPositiveMinSpeed) * delta;
    }


    /**
      Convert kg's value to angl
    */
    function kgToAng(value) {
        // for little values
        value = value * root.angK;
        var deltaForNegativeValue = root.minMotorKg < 0 ? Math.abs(root.minMotorKg) : 0;
        var deltaForPositiveValue = root.minMotorKg > 0 ? -1 * root.minMotorKg : 0;

        // Working range of left bar
        var diapAng = 180 - (180 - (dl2.rotation - dl1.rotation));

        // Range of kg
        var diapKg = (root.maxMotorKg - root.minMotorKg) * root.angK;
        var delta = diapAng / diapKg;
        var res =  (value + deltaForNegativeValue + deltaForPositiveValue);

        return (value === root.minMotorKg ? res + 0.1 : res) * delta + (dl1.rotation - 90);
    }


    /**
      Convert power's value to angl
    */
    function powerToAng(value) {
        var deltaForNegativeValue = root.minPower < 0 ? Math.abs(root.minPower) : 0;
        var deltaForPositiveValue = root.minPower > 0 ? -1 * root.minPower : 0;

        // Working range of right bar
        var diapAng = 180 - (180 - (dl2.rotation - dl1.rotation));

        // Range of power
        var diapPower = root.maxPower - root.minPower;
        var delta = diapAng / diapPower;
        var res =  (dl2.rotation - 90) - (value + deltaForNegativeValue + deltaForPositiveValue) * delta;

        // 0.1 - is a little fix for canvas context.arc
        return (value === root.minPower ? res + 0.1 : res)
    }

    Column {
        anchors.fill: parent

        Item {
            width: diameter
            height: diameter

            Component.onCompleted: {}

            Rectangle {
                id: baseLayer
                width: root.diameter
                height: root.diameter
                radius: root.diameter / 2
                color: root.color
                border.color: root.borderColor
                border.width: 3

                Item {
                    id: diagonalLine
                    anchors.fill: parent

                    Rectangle {
                        id: dl1
                        width: 1
                        height: root.diameter
                        antialiasing: true
                        color: root.borderColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        layer.smooth: true
                        rotation: root.diagLAnc
                    }

                    Rectangle {
                        id: dl2
                        width: 1
                        height: root.diameter
                        antialiasing: true
                        color: root.borderColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        layer.smooth: true
                        rotation: 180 - root.diagLAnc
                    }
                }


                /**
                  All 4 scales
                  */
                Item {
                    id: progressBars
                    anchors.fill: parent

                    property real ropeStartAng: dl2.rotation
                    property real ropeEndAng: ropeToAng(Math.min(root.ropeMeters, root.maxRopeMeters))

                    property real speedStartAng: speedToAng(0)
                    property real speedEndAng: speedToAng(Math.min(root.speedMs, root.maxSpeedMs));

                    property real motorKgStartAng: dl1.rotation - 90
                    property real motorKgEndAng: kgToAng(Math.min(root.motorKg, root.maxMotorKg));

                    property real powerStartAng: 0
                    property real powerEndAng: powerToAng(Math.min(root.power, root.maxPower));

                    // Animation
                    Behavior on ropeEndAng {
                       id: animationRopeEndAng
                       enabled: root.enableAnimation
                       NumberAnimation {
                           duration: root.animationDuration
                           easing.type: root.animationType
                       }
                    }

                    Behavior on speedEndAng {
                       id: animationSpeedEndAng
                       enabled: root.enableAnimation
                       NumberAnimation {
                           duration: root.animationDuration
                           easing.type: root.animationType
                       }
                    }

                    Behavior on motorKgEndAng {
                       id: animationMotorKgEndAng
                       enabled: root.enableAnimation
                       NumberAnimation {
                           duration: root.animationDuration
                           easing.type: root.animationType
                       }
                    }

                    Behavior on powerEndAng {
                       id: animationPowerEndAng
                       enabled: root.enableAnimation
                       NumberAnimation {
                           duration: root.animationDuration
                           easing.type: root.animationType
                       }
                    }

                    onRopeEndAngChanged: canvas.requestPaint()
                    onSpeedEndAngChanged: canvas.requestPaint()
                    onMotorKgEndAngChanged: canvas.requestPaint()
                    onPowerEndAngChanged: canvas.requestPaint()

                    function getColors(value, min, max, wcp, dcp, wc, dc, c, tc) {
                        var warningZone = wcp * max;
                        var dangerZone = dcp * max;

                        var color = c;
                        var textColor = tc;

                        if (Math.abs(value) >= warningZone && Math.abs(value) < dangerZone) {
                            textColor = color = wc;
                        } else if (Math.abs(value) >= dangerZone) {
                            textColor = color = dc;
                        }

                        return { color, textColor };
                    }

                    Canvas {
                        id: canvas
                        opacity: root.baseOpacity
                        antialiasing: true
                        contextType: '2d'
                        anchors.fill: parent
                        onPaint: {
                            if (context) {
                                context.reset();

                                var centreX = baseLayer.width / 2;
                                var centreY = baseLayer.height / 2;

                                /** ФОН */
                                context.globalCompositeOperation = 'source-over';
                                context.fillStyle = root.gaugeColor;
                                context.beginPath();
                                context.ellipse(0 + 3, 0 + 3, baseLayer.width - 6, baseLayer.height - 6);
                                context.fill();
                                context.globalCompositeOperation = 'xor';
                                context.fillStyle = root.gaugeColor;
                                context.beginPath();
                                context.ellipse(
                                    circleInner.x,
                                    circleInner.y + (root.diameter * 0.045),
                                    circleInner.width,
                                    circleInner.height - (root.diameter * 0.09)
                                );
                                context.fill();

                                /********** Top ***********/

                                var topEnd = (Math.PI * (parent.ropeEndAng - 90)) / 180;
                                var topStart = (Math.PI * (parent.ropeStartAng + 90)) / 180;

                                context.beginPath();
                                context.arc(
                                    centreX,
                                    centreY,
                                    baseLayer.radius,
                                    topStart,
                                    topEnd,
                                    false
                                );

                                context.globalCompositeOperation = 'source-atop';
                                context.lineWidth = 200;

                                var ropeColors = parent.getColors(
                                    root.ropeMeters,
                                    root.minRopeMeters,
                                    root.maxRopeMeters,
                                    root.ropeWarningColorPercent,
                                    root.ropeDangerColorPercent,
                                    root.ropeWarningColor,
                                    root.ropeDangerColor,
                                    root.ropeColor,
                                    'black'
                                );

                                context.strokeStyle = ropeColors.color;
                                context.stroke();

                                /********** Bottom ***********/

                                var bottomStart = (Math.PI * (parent.speedStartAng - 90)) / 180;
                                var bottomEnd = (Math.PI * (parent.speedEndAng - 90)) / 180;

                                context.beginPath();
                                context.arc(
                                    centreX,
                                    centreY,
                                    baseLayer.radius,
                                    bottomStart,
                                    bottomEnd,
                                    parent.speedEndAng < 180
                                );

                                context.globalCompositeOperation = 'source-atop';
                                context.lineWidth = 200;

                                var speedColors = parent.getColors(
                                    root.speedMs,
                                    root.minSpeedMs,
                                    root.maxSpeedMs,
                                    root.speedWarningColorPercent,
                                    root.speedDangerColorPercent,
                                    root.speedWarningColor,
                                    root.speedDangerColor,
                                    root.speedColor,
                                    'black'
                                );

                                context.strokeStyle = speedColors.color;
                                context.stroke();

                                /********** Left ***********/

                                var leftEnd = (Math.PI * (parent.motorKgStartAng + 180)) / 180;
                                var leftStart = (Math.PI * (parent.motorKgEndAng - 180)) / 180;

                                context.beginPath();
                                context.arc(
                                    centreX,
                                    centreY,
                                    baseLayer.radius - root.gaugeHeight * 0.4,
                                    leftStart,
                                    leftEnd,
                                    true
                                );

                                context.lineWidth = root.gaugeHeight * 0.7;

                                var kgColors = parent.getColors(
                                    root.motorKg,
                                    root.minMotorKg,
                                    root.maxMotorKg,
                                    root.motorKgWarningColorPercent,
                                    root.motorKgDangerColorPercent,
                                    root.motorKgWarningColor,
                                    root.motorKgDangerColor,
                                    root.motorKgColor,
                                    'black'
                                );

                                context.strokeStyle = kgColors.color;
                                context.stroke();

                                /********** Right ***********/

                                var rightEnd = (Math.PI * (parent.powerEndAng)) / 180;
                                var rightStart = (Math.PI * (parent.powerStartAng)) / 180;

                                context.beginPath();
                                context.arc(
                                    centreX,
                                    centreY,
                                    baseLayer.radius - root.gaugeHeight * 0.4,
                                    rightStart,
                                    rightEnd,
                                    parent.powerEndAng < 0
                                );

                                context.lineWidth = root.gaugeHeight * 0.7;

                                var powerColors = parent.getColors(
                                    root.power,
                                    root.minPower,
                                    root.maxPower,
                                    root.powerWarningColorPercent,
                                    root.powerDangerColorPercent,
                                    root.powerWarningColor,
                                    root.powerDangerColor,
                                    root.powerColor,
                                    'black'
                                );

                                powerTxt2.color = powerTxt1.color = powerColors.textColor;
                                context.strokeStyle = powerColors.color;
                                context.stroke();
                            }
                        }
                        onWidthChanged:  { requestPaint(); }
                        onHeightChanged: { requestPaint(); }
                    }

                    Canvas {
                        //opacity: 0.5
                        antialiasing: true
                        contextType: '2d'
                        anchors.fill: parent
                        onPaint: {
                            if (context) {
                                context.reset ();
                                context.beginPath();

                                var centreX = baseLayer.width / 2;
                                var centreY = baseLayer.height / 2;

                                var topEnd = (Math.PI * (90 - dl1.rotation)) / 180;
                                var topStart = (Math.PI * (90 - dl2.rotation)) / 180;

                                context.beginPath();
                                context.moveTo(centreX, centreY);
                                context.arc(
                                    centreX,
                                    centreY,
                                    baseLayer.radius - root.gaugeHeight * 0.7,
                                    topStart,
                                    topEnd,
                                    false
                                );

                                context.lineTo(centreX, centreY);
                                context.fillStyle = root.innerColor;
                                context.fill()

                                topEnd = (Math.PI * (90 + dl2.rotation)) / 180;
                                topStart = (Math.PI * (90 + dl1.rotation)) / 180;

                                context.beginPath();
                                context.moveTo(centreX, centreY);
                                context.arc(
                                    centreX,
                                    centreY,
                                    baseLayer.radius - root.gaugeHeight * 0.7,
                                    topStart,
                                    topEnd,
                                    false
                                );

                                context.lineTo(centreX, centreY);
                                context.fillStyle = root.innerColor;
                                context.fill();
                            }
                        }
                    }
                }

                Item {
                    id: circleInner

                    anchors {
                        fill: parent
                        margins: gaugeHeight
                        centerIn: parent
                    }
                }

                Item {
                    id: gauge
                    anchors {
                        fill: parent
                        margins: gaugeHeight * 0.1
                    }

                    function getTLHY(value, min, max, k = 0.2) {
                        if (value === max) {
                            return root.gaugeHeight * k;
                        } else if (value === min) {
                            return root.gaugeHeight * -k;
                        }
                        return 0;
                    }

                    function getTLHX(value, min, max, k = 0.13) {
                        if (value === max) {
                            return root.gaugeHeight * -k;
                        } else if (value === min) {
                            return root.gaugeHeight * -k;
                        }
                        return 0;
                    }

                    function getTLVY(value, min, max, k = 0.2) {
                        if (value === max) {
                            return root.gaugeHeight * k;
                        } else if (value === min) {
                            return root.gaugeHeight * k;
                        }
                        return 0;
                    }

                    function getTLVX(value, min, max, k = 0.13) {
                        if (value === max) {
                            return root.gaugeHeight * k;
                        } else if (value === min) {
                            return root.gaugeHeight * -k;
                        }
                        return 0;
                    }

                    // k - percentage of the scale that is marked in red
                    function getTLColor(value, max, k = 20) {
                        return value >= (max - (max * k / 100))
                                ? root.gaugeDangerFontColor
                                : root.gaugeFontColor;
                    }

                    function getFontSize(k = 0.04) {
                        return Math.max(10, root.diameter * k);
                    }

                    /**
                      KG
                    */
                    CircularGauge {
                        id: kgGauge

                        anchors {
                            fill: parent
                            margins: 0
                        }

                        minimumValue: root.minMotorKg
                        maximumValue: root.maxMotorKg
                        value: root.motorKg

                        Behavior on value {
                           id: animationValueKg
                           enabled: root.enableAnimation
                           NumberAnimation {
                               duration: root.animationDuration
                               easing.type: root.animationType
                           }
                        }

                        style: CircularGaugeStyle {
                            minimumValueAngle: -dl2.rotation
                            maximumValueAngle: -dl1.rotation
                            labelInset: root.gaugeHeight
                            labelStepSize: root.motorKgLabelStepSize

                            /**
                              Center point
                            */
                            foreground: Item {
                                visible: false
                            }

                            /**
                              Numbers on the scale
                            */
                            tickmarkLabel:  Text {
                                function getText() {
                                    var val = root.prettyNumber(styleData.value, root.maxMotorKg > 1 ? 0 : 2);
                                    return val + ((styleData.value === root.minMotorKg) ? 'kg' : '');
                                }

                                font.pixelSize: gauge.getFontSize()
                                y: gauge.getTLHY(styleData.value, root.minMotorKg, root.maxMotorKg)
                                x: gauge.getTLHX(styleData.value, root.minMotorKg, root.maxMotorKg)
                                color: gauge.getTLColor(styleData.value, root.maxMotorKg)
                                text: this.getText()
                                rotation: root.kgToAng(styleData.value)
                                antialiasing: true
                                font.family: root.ff
                            }

                            /**
                              Small tickmark
                            */
                            minorTickmark: Rectangle {
                                antialiasing: true
                                visible: root.maxMotorKg <= 50
                                implicitWidth: outerRadius * ((styleData.value === root.maxMotorKg || styleData.value === root.minMotorKg)
                                    ? 0.005
                                    : 0.01)
                                implicitHeight:  (styleData.value === root.maxMotorKg || styleData.value === root.minMotorKg)
                                    ? root.gaugeHeight
                                    : implicitWidth * (styleData.value % (root.motorKgLabelStepSize) ? 3 : 6)
                                color: gauge.getTLColor(styleData.value, root.maxMotorKg)
                            }

                            /**
                              Tickmark
                            */
                            tickmark: Rectangle {
                                antialiasing: true
                                implicitWidth: outerRadius * ((styleData.value === root.maxMotorKg || styleData.value === root.minMotorKg)
                                    ? 0.005
                                    : 0.01)
                                implicitHeight:  (styleData.value === root.maxMotorKg || styleData.value === root.minMotorKg)
                                    ? root.gaugeHeight
                                    : implicitWidth * (styleData.value % (root.motorKgLabelStepSize / 2) ? 3 : 6)
                                color: gauge.getTLColor(styleData.value, root.maxMotorKg)
                            }

                            /**
                              Needle
                            */
                            needle: Rectangle {
                                antialiasing: true
                                width: outerRadius * 0.015
                                height: outerRadius * 0.7
                                color: root.gaugeFontColor
                            }
                        }
                    }

                    /**
                      Power
                    */
                    CircularGauge {
                        id: powerGauge

                        anchors {
                            fill: parent
                            margins: 0
                        }

                        minimumValue: root.minPower
                        maximumValue: root.maxPower
                        value: root.power

                        Behavior on value {
                           id: animationValuePower
                           enabled: root.enableAnimation
                           NumberAnimation {
                               duration: root.animationDuration
                               easing.type: root.animationType
                           }
                        }

                        style: CircularGaugeStyle {
                            minimumValueAngle: dl2.rotation
                            maximumValueAngle: dl1.rotation
                            labelInset: root.gaugeHeight
                            labelStepSize: root.powerLabelStepSize

                            foreground: Item {
                                Rectangle {
                                    width: 10
                                    height: width
                                    radius: width / 2
                                    color: root.gaugeFontColor
                                    antialiasing: true
                                    anchors.centerIn: parent
                                }
                            }

                            tickmarkLabel:  Text {
                                font.pixelSize: gauge.getFontSize()
                                y: gauge.getTLHY(styleData.value, root.minPower, root.maxPower)
                                x: gauge.getTLHX(styleData.value, root.minPower, root.maxPower, -0.13)
                                text: styleData.value + ((styleData.value === 0) ? 'kw' : '')
                                rotation: root.powerToAng(styleData.value)
                                color: gauge.getTLColor(Math.abs(styleData.value), root.maxPower)
                                antialiasing: true
                                font.family: root.ff
                            }

                            minorTickmark: Rectangle {
                                visible: false
                            }

                            tickmark: Rectangle {
                                antialiasing: true
                                implicitWidth: outerRadius * ((styleData.value === root.maxPower || styleData.value === root.minPower)
                                    ? 0.005
                                    : 0.01)
                                implicitHeight:  (styleData.value === root.maxPower || styleData.value === root.minPower)
                                    ? root.gaugeHeight
                                    : implicitWidth * ((styleData.value % (root.powerLabelStepSize)) ? 3 : 6)
                                color: gauge.getTLColor(Math.abs(styleData.value), root.maxPower)
                            }

                            needle: Rectangle {
                                antialiasing: true
                                width: outerRadius * 0.015
                                height: outerRadius * 0.7
                                color: root.gaugeFontColor
                            }
                        }
                    }

                    /**
                      Speed
                    */
                    CircularGauge {
                        id: speedMsGauge

                        anchors {
                            fill: parent
                            margins: 0
                        }

                        minimumValue: root.minSpeedMs
                        maximumValue: root.maxSpeedMs
                        value: root.speedMs

                        Behavior on value {
                           id: animationValueSpeed
                           enabled: root.enableAnimation
                           NumberAnimation {
                               duration: root.animationDuration
                               easing.type: root.animationType
                           }
                        }

                        style: CircularGaugeStyle {
                            minimumValueAngle: root.speedToAng(root.minSpeedMs)
                            maximumValueAngle: root.speedToAng(root.maxSpeedMs)
                            labelInset: root.gaugeHeight / 2
                            labelStepSize: root.maxSpeedMs

                            foreground: Item {
                                Rectangle {
                                    visible: false
                                }
                            }

                            tickmarkLabel:  Text {
                                visible: styleData.value === root.maxSpeedMs || styleData.value === root.minSpeedMs

                                font.pixelSize: gauge.getFontSize(0.04)

                                y: gauge.getTLVY(styleData.value, root.minSpeedMs, root.maxSpeedMs, 0.3)
                                x: gauge.getTLVX(styleData.value, root.minSpeedMs, root.maxSpeedMs, -0.3)


                                text: styleData.value + ((styleData.value === 0) ? 'kw' : '')

                                rotation: styleData.value !== root.maxSpeedMs ? root.speedToAng(styleData.value) - 180 - 90 : root.speedToAng(styleData.value)  - 90

                                color: root.gaugeFontColor
                                antialiasing: true
                                font.family: root.ff
                            }

                            minorTickmark: Rectangle {
                                visible: false
                            }

                            tickmark: Rectangle {
                                antialiasing: true
                                implicitWidth: outerRadius * ((styleData.value === root.maxSpeedMs || styleData.value === root.minSpeedMs)
                                    ? 0.005
                                    : 0.01)
                                implicitHeight:  (styleData.value === root.maxSpeedMs || styleData.value === root.minSpeedMs)
                                    ? root.gaugeHeight
                                    : implicitWidth * ((styleData.value % (root.maxSpeedMs)) ? 3 : 6)
                                color: root.gaugeFontColor
                            }

                            needle: Rectangle {
                                visible: false
                            }
                        }
                    }

                    /**
                      Rope
                    */
                    CircularGauge {
                        id: ropeMetersGauge

                        anchors {
                            fill: parent
                            margins: 0
                        }

                        minimumValue: root.minRopeMeters
                        maximumValue: root.maxRopeMeters
                        value: root.ropeMeters

                        Behavior on value {
                           id: animationValueRope
                           enabled: root.enableAnimation
                           NumberAnimation {
                               duration: root.animationDuration
                               easing.type: root.animationType
                           }
                        }

                        style: CircularGaugeStyle {
                            minimumValueAngle: root.ropeToAng(root.minRopeMeters)
                            maximumValueAngle: root.ropeToAng(root.maxRopeMeters)
                            labelInset: root.gaugeHeight / 2
                            labelStepSize: root.maxRopeMeters

                            foreground: Item {
                                Rectangle {
                                    visible: false
                                }
                            }

                            tickmarkLabel:  Text {
                                function getAng(value) {
                                    var ang = root.ropeToAng(value);
                                    return value !== root.maxRopeMeters
                                        ? (ang - 180 - 90)
                                        : (ang - 90);
                                }

                                function show(value) {
                                    var ifMax = value === root.maxRopeMeters;
                                    var ifMin = value === root.minRopeMeters;
                                    return ifMax || ifMin;
                                }

                                visible: this.show(styleData.value)
                                font.pixelSize: gauge.getFontSize(0.04)
                                y: gauge.getTLVY(styleData.value, root.minRopeMeters, root.maxRopeMeters, -0.3)
                                x: gauge.getTLVX(styleData.value, root.minRopeMeters, root.maxRopeMeters, -0.3)
                                text: styleData.value + ((styleData.value === 0) ? 'm' : '')
                                rotation: this.getAng(styleData.value)
                                color: root.gaugeFontColor
                                antialiasing: true
                                font.family: root.ff
                            }

                            minorTickmark: Rectangle {
                                visible: false
                            }

                            tickmark: Rectangle {
                                visible: false
                            }

                            needle: Rectangle {
                                visible: false
                            }
                        }
                    }
                }

                /**
                  Values of ropeMeters and leftRopeMeters
                  */
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: root.gaugeHeight / 2 - root.gaugeHeight * 0.3
                    spacing: 2
                    width: Math.max(textLeftRopeMeters.width, ropeMeters.width)


                    Grid {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        id: textLeftRopeMeters

                        Text {
                            text: isNaN(root.leftRopeMeters)
                                  ? root.maxRopeMeters
                                  : root.prettyNumber(root.leftRopeMeters)
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            font.family: root.ff
                            font.bold: root.boldValues
                        }

                        Text {
                            text: 'm'
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            font.family: root.ff
                            font.bold: root.boldValues
                        }
                    }

                    Rectangle {
                        opacity: 0.5
                        width: parent.width
                        height: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.borderColor
                    }

                    Grid {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        id: textRopeMeters

                        Text {
                            text: root.prettyNumber(root.ropeMeters)
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            font.family: root.ff
                            font.bold: root.boldValues
                        }

                        Text {
                            text: 'm'
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            font.family: root.ff
                            font.bold: root.boldValues
                        }
                    }
                }

                /**
                  Value of speedMs
                  */
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.gaugeHeight / 1.5
                    spacing: 5

                    Text {
                        text: root.prettyNumber(root.speedMs)
                        font.pixelSize: Math.max(10, root.diameter * 0.04)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }

                    Text {
                        text: 'ms'
                        font.pixelSize: Math.max(10, root.diameter * 0.04)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }
                }

                /**
                  Motor mode
                  */
                Text {
                    text: root.motorMode
                    anchors.horizontalCenter: parent.horizontalCenter

                    anchors.top: parent.top
                    anchors.topMargin: root.gaugeHeight * 2.4
                    font.pixelSize: Math.max(10, root.diameter * 0.055)
                    font.family: root.ff
                }

                /**
                  Value of motorKg
                  */
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: root.gaugeHeight * 3.4
                    spacing: 5

                    Text {
                        text: root.prettyNumber(root.motorKg)
                        font.pixelSize: Math.max(10, root.diameter * 0.055)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }

                    Text {
                        text: 'kg'
                        opacity: 0.8
                        font.pixelSize: Math.max(10, root.diameter * 0.055)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }
                }

                /**
                  Value of power
                  */
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.gaugeHeight * 3.4
                    spacing: 5

                    Text {
                        id: powerTxt1
                        text: root.prettyNumber(root.power, 1)
                        font.pixelSize: Math.max(10, root.diameter * 0.055)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }

                    Text {
                        id: powerTxt2
                        text: 'kw'
                        opacity: 0.8
                        font.pixelSize: Math.max(10, root.diameter * 0.055)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }
                }

                /**
                  Title 'Power'
                  */
                Text {
                    text: 'Power'
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.gaugeHeight * 2.4
                    font.pixelSize: Math.max(10, root.diameter * 0.035)
                    font.family: root.ff
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 200
            anchors.horizontalCenter: parent.horizontalCenter

            Grid {
                visible: root.debug
                columns: 2
                anchors.fill: parent

                Column {
                    spacing: 10

                    Column {
                        spacing: 5

                        Text {
                            text: 'Rope'
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Slider {
                            id: sliderRope
                            minimumValue: root.minRopeMeters
                            maximumValue: root.maxRopeMeters
                            value: root.ropeMeters

                            onValueChanged: {
                                var res = ropeToAng(value);
                                root.ropeMeters = value;
                            }
                        }
                    }

                    Column {
                        spacing: 5

                        Text {
                            text: 'Speed'
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Slider {
                            id: sliderSpeed
                            minimumValue: root.minSpeedMs
                            maximumValue: root.maxSpeedMs
                            value: root.speedMs

                            onValueChanged: {
                                var res = speedToAng(value);
                                root.speedMs = value;
                            }
                        }
                    }
                }

                Column {
                    spacing: 10
                    Column {
                        spacing: 5

                        Text {
                            text: 'Kg'
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Slider {
                            id: sliderKg
                            minimumValue: root.minMotorKg
                            maximumValue: root.maxMotorKg
                            value: root.motorKg

                            onValueChanged: {
                                var res = kgToAng(value);
                                root.motorKg = value;
                            }
                        }
                    }

                    Column {
                        spacing: 5

                        Text {
                            text: 'Power'
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Slider {
                            id: sliderPower
                            minimumValue: root.minPower
                            maximumValue: root.maxPower
                            value: root.power

                            onValueChanged: {
                                var res = powerToAng(value);
                                root.power = value;
                            }
                        }
                    }
                }
            }
        }
    }
}
