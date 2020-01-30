import QtQuick 2.12
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4

import QtQml 2.2


import QtGraphicalEffects 1.0;

Rectangle {
    id:root
    anchors.fill: parent

    /********************
            Params
    ********************/
    property double speedMs: 0
    property double minSpeedMs: -10
    property double maxSpeedMs: 120

    property double ropeMeters: 0
    property double minRopeMeters: 0
    property double maxRopeMeters: 800
    property double leftRopeMeters: maxRopeMeters - ropeMeters

    property double power: 0
    property double minPower: -20
    property double maxPower: 20

    property double motorKg: 150
    property double minMotorKg: 0
    property double maxMotorKg: 180

    property double tempFets: 0
    property double tempMotor: 0
    property double tempBat: 0

    property double whIn: 0
    property double whOut: 0

    property string motorMode

    /********************
        Default view
    ********************/
    property int diameter: parent.width > parent.height
       ? parent.height
       : parent.width

    property string borderColor: "#515151"      // Цвет границ
    property string color: "#efeded"            // Цвет основного фона
    property int diagLAnc: 55                   // Угол диагональных линий от 12ти часов

    /********************
            Gauge
    ********************/
    property double gaugeHeight: diameter * 0.08;
    property int animationDuration: 100

    function prettyNumber(number) {
        return number.toFixed(1);
    }

    function showStatsInConsole() {
        console.log(qsTr("MotorMode: %1").arg(motorMode));
        console.log(qsTr("Power: %1w").arg(power));
        console.log(qsTr("SpeedMs: %1ms").arg(speedMs));
        console.log(qsTr("RopeMeters %1m, leftMeters: %2m")
                    .arg(ropeMeters)
                    .arg(leftRopeMeters));
        console.log(qsTr("TempFets %1C, TempMotor: %2C, TempBat: %3C")
                    .arg(tempFets)
                    .arg(tempMotor)
                    .arg(tempBat));
        console.log(qsTr("WhIn %1, WhOut: %2")
                    .arg(whIn)
                    .arg(whOut));
    }

    function ropeToAng(value) {
        // 180 - (125 - 55) = 110. рабочий диапазон при дефолтном diagLAnc: -55 до 55

        // Если шкала начинается с отрицательного значения
        var deltaForNegativeMinRope = root.minRopeMeters < 0 ? Math.abs(root.minRopeMeters) : 0;

        // Если шкала начинается с положительного значения
        var deltaForPositiveMinRope = root.minRopeMeters > 0 ? -1 * root.minRopeMeters : 0;

        // Рабочий диапазон нижнего бара в градусах
        var diapAng = 180 - (dl2.rotation - dl1.rotation);

        // Диапазон веревки
        var diapRope = root.maxRopeMeters - root.minRopeMeters;
        var delta = diapAng / diapRope;

        var res = (value + deltaForNegativeMinRope + deltaForPositiveMinRope) * delta;

        // При 0 все распидарасит, поэтому небольшой костыль в 0,1
        return (res === 0 ? res + 0.1 : res)  - dl1.rotation;
    }

    function speedToAng(value) {
        // 180 - (125 - 55) = 110. рабочий диапазон при дефолтном diagLAnc: 125 - 235

        // Если шкала начинается с отрицательного значения
        var deltaForNegativeMinSpeed = root.minSpeedMs < 0 ? Math.abs(root.minSpeedMs) : 0;

        // Если шкала начинается с положительного значения
        var deltaForPositiveMinSpeed = root.minSpeedMs > 0 ? -1 * root.minSpeedMs : 0;

        // Рабочий диапазон нижнего бара в градусах
        var diapAng = 180 - (dl2.rotation - dl1.rotation);

        // Диапазон скорости
        var diapSpeed = root.maxSpeedMs - root.minSpeedMs;
        var delta = diapAng / diapSpeed;

        return (dl2.rotation + diapAng) - (value + deltaForNegativeMinSpeed + deltaForPositiveMinSpeed) * delta;
    }

    function kgToAng(value) {
        // -125 -55

        // Если шкала начинается с отрицательного значения
        var deltaForNegativeValue = root.minMotorKg < 0 ? Math.abs(root.minMotorKg) : 0;

        // Если шкала начинается с положительного значения
        var deltaForPositiveValue = root.minMotorKg > 0 ? -1 * root.minMotorKg : 0;

        // Рабочий диапазон нижнего бара в градусах
        var diapAng = 180 - (180 - (dl2.rotation - dl1.rotation));

        // Диапазон скорости
        var diapKg = root.maxMotorKg - root.minMotorKg;
        var delta = diapAng / diapKg;

        // 20 - регулировка
        var res =  (value + deltaForNegativeValue + deltaForPositiveValue);


        return (res === 0 ? res + 0.1 : res) * delta + (dl1.rotation - diapAng - 20);
    }


    /*gradient: Gradient {
        GradientStop { position: 0.0; color: "#5b365f" }
        GradientStop { position: 1.0; color: "#ce566a" }
    } */


    Row {
        Slider {
            id: sliderRope
            minimumValue: root.minRopeMeters
            maximumValue: root.maxRopeMeters
            value: root.ropeMeters

            onValueChanged: {
                var res = ropeToAng(value)

                topAndBottomProgressBars.ropeEndAng = res;
                topBarText.text = parseInt(value, 10) + 'm / ' + (root.maxRopeMeters - parseInt(value, 10)) + 'm';
            }
        }

        Slider {
            id: sliderSpeed
            minimumValue: root.minSpeedMs
            maximumValue: root.maxSpeedMs
            value: root.speedMs;

            onValueChanged: {
                var res = speedToAng(value);
                topAndBottomProgressBars.speedEndAng = res;
                bottomBarText.text = prettyNumber(value) + 'ms';
            }
        }

        Slider {
            id: sliderKg
            minimumValue: root.minMotorKg
            maximumValue: root.maxMotorKg
            value: root.motorKg;

            onValueChanged: {
                var res = kgToAng(value);
                topAndBottomProgressBars.motorKgEndAng = res;
                kgGauge.value = value
                //bottomBarText.text = prettyNumber(value) + 'ms';
            }
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent
        anchors.top: parent.top
        anchors.topMargin: 10

        width: diameter
        height: diameter

        Component.onCompleted: {
            power = prettyNumber(power);
            speedMs = prettyNumber(speedMs);
            motorKg = prettyNumber(motorKg);
            tempFets = prettyNumber(tempFets);
            tempMotor = prettyNumber(tempMotor);
            tempBat = prettyNumber(tempBat);
            whIn = prettyNumber(whIn);
            whOut = prettyNumber(whOut);
            ropeMeters = prettyNumber(ropeMeters);
            leftRopeMeters = prettyNumber(leftRopeMeters);
            showStatsInConsole();
        }

        Rectangle {
            id: baseLayer

            anchors.fill: parent
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
                    width: 2
                    height: root.diameter
                    transformOrigin: parent.left
                    antialiasing: true
                    color: root.borderColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    layer.smooth: true
                    rotation: root.diagLAnc
                }

                Rectangle {
                    id: dl2
                    width: 2
                    height: root.diameter
                    transformOrigin: parent.left
                    antialiasing: true
                    color: root.borderColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    layer.smooth: true
                    rotation: 180 - root.diagLAnc
                }
            }

            Item {
                id: topAndBottomProgressBars

                anchors.fill: parent

                property real ropeStartAng: dl2.rotation
                property real ropeEndAng: ropeToAng(root.ropeMeters)

                property real speedStartAng: dl1.rotation
                property real speedEndAng: speedToAng(root.speedMs);

                property real motorKgStartAng: dl1.rotation - 90
                property real motorKgEndAng: kgToAng(root.motorKg);

                property real powerStartAng: dl2.rotation - 90
                property real powerEndAng: kgToAng(root.power);

                property real lineWidth: 20

                /*Behavior on ropeEndAng {
                       id: animationRopeEndAng
                       enabled: true
                       NumberAnimation {
                           duration: root.animationDuration
                           easing.type: Easing.InOutCubic
                       }
                    }

                Behavior on speedEndAng {
                   id: animationSpeedEndAng
                   enabled: true
                   NumberAnimation {
                       duration: root.animationDuration
                       easing.type: Easing.InOutCubic
                   }
                }

                Behavior on motorKgEndAng {
                   id: animationMotorKgEndAng
                   enabled: true
                   NumberAnimation {
                       duration: root.animationDuration
                       easing.type: Easing.InOutCubic
                   }
                }

                Behavior on powerEndAng {
                   id: animationPowerEndAng
                   enabled: true
                   NumberAnimation {
                       duration: root.animationDuration
                       easing.type: Easing.InOutCubic
                   }
                }*/

                onRopeEndAngChanged: canvas.requestPaint()
                onSpeedEndAngChanged: canvas.requestPaint()
                onMotorKgEndAngChanged: canvas.requestPaint()
                onPowerEndAngChanged: canvas.requestPaint()

                Canvas {
                    id: canvas
                    opacity: 0.35;
                    antialiasing: true;
                    contextType: "2d";
                    anchors.fill: parent
                    onPaint: {
                        if (context) {
                            context.reset ();

                            var centreX = baseLayer.width / 2;
                            var centreY = baseLayer.height / 2;

                            /** ФОН */
                            context.globalCompositeOperation = "source-over";
                            context.fillStyle = "#474747";
                            context.beginPath ();
                            context.ellipse (0 + 3, 0 + 3, baseLayer.width - 6, baseLayer.height - 6);
                            context.fill ();
                            context.globalCompositeOperation = "xor";
                            context.fillStyle = "#474747";
                            context.beginPath ();
                            context.ellipse (circleInner.x, circleInner.y + 20, circleInner.width, circleInner.height-40);
                            context.fill ();


                            /********** Верхний спидометр ***********/

                            var topEnd = (Math.PI * (parent.ropeEndAng - 90)) / 180
                            var topStart = (Math.PI * (parent.ropeStartAng + 90)) / 180

                            context.beginPath();
                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius,
                                topStart,
                                topEnd,
                                false
                            );

                            context.globalCompositeOperation = "source-atop";
                            context.lineWidth = 200
                            context.strokeStyle = "red"
                            context.stroke()

                            /********** Нижний спидометр ***********/

                            var bottomStart = (Math.PI * (parent.speedStartAng + 90)) / 180
                            var bottomEnd = (Math.PI * (parent.speedEndAng - 90)) / 180

                            context.beginPath();
                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius,
                                bottomStart,
                                bottomEnd,
                                true
                            );

                            context.globalCompositeOperation = "source-atop";
                            context.lineWidth = 200;
                            context.strokeStyle = "blue";
                            context.stroke();

                            /********** Левый спидометр ***********/

                            var leftEnd = (Math.PI * (parent.motorKgStartAng + 180)) / 180
                            var leftStart = (Math.PI * (parent.motorKgEndAng - 180)) / 180

                            context.beginPath();
                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius - root.gaugeHeight * 0.43,
                                leftStart,
                                leftEnd,
                                true
                            );


                            context.lineWidth = root.gaugeHeight * 0.7
                            context.strokeStyle = "steelblue";
                            context.stroke()

                            /********** Правый спидометр ***********/

                            /*context.beginPath();
                            context.strokeStyle = "steelblue";
                            context.lineWidth = outerRadius*0.02;

                            //var leftStart = (Math.PI * (parent.leftStartAng + 90)) / 180
                            //var leftEnd = (Math.PI * (parent.leftEndAng - 90)) / 180

                            var leftEnd = (Math.PI * (root.kgToAng(160))) / 180
                            var leftStart = (Math.PI * (root.kgToAng(root.minMotorKg))) / 180

                            context.arc(
                                outerRadius,
                                outerRadius,
                                baseLayer.radius - root.gaugeHeight * 0.43,
                                leftStart,
                                leftEnd,
                                false
                            );

                            context.lineWidth = root.gaugeHeight * 0.7
                            context.strokeStyle = "blue"
                            context.stroke()*/
                        }
                    }
                    onWidthChanged:  { requestPaint (); }
                    onHeightChanged: { requestPaint (); }
                }
                Canvas {  // draws the ring
                    //opacity: 0.5
                    antialiasing: true;
                    contextType: "2d";
                    anchors.fill: parent
                    onPaint: {
                        if (context) {
                            context.reset ();

                            context.beginPath();

                            var centreX = baseLayer.width / 2;
                            var centreY = baseLayer.height / 2;

                            var topEnd = (Math.PI * (90 - dl1.rotation - 1)) / 180
                            var topStart = (Math.PI * (90 - dl2.rotation + 1)) / 180

                            console.log(dl1.rotation, dl2.rotation)
                            context.beginPath();
                            context.moveTo(centreX, centreY);
                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius - root.gaugeHeight * 0.5,
                                topStart,
                                topEnd,
                                false
                            );

                            context.lineTo(centreX, centreY);
                            context.fillStyle = "#efeded"
                            context.fill()

                            topEnd = (Math.PI * (90 + dl2.rotation - 1)) / 180
                            topStart = (Math.PI * (90 + dl1.rotation + 1 )) / 180

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
                            context.fillStyle = "#efeded"
                            context.fill()
                        }
                    }
                }
            }

            /**
              Внетренний круг
            */
            Item {
                id: circleInner;

                anchors {
                    fill: parent;
                    margins: gaugeHeight;
                    centerIn: parent
                }
            }

            CircularGauge {
                id: kgGauge
                anchors {
                    fill: parent;
                    margins: gaugeHeight * 0.06;
                }

                property int labelStepSize: 30


                minimumValue: root.minMotorKg
                maximumValue: root.maxMotorKg

                value: root.motorKg

                style: CircularGaugeStyle {
                    minimumValueAngle: -125
                    maximumValueAngle: -55
                    labelInset: 50

                    labelStepSize: parent.labelStepSize

                    foreground: Item {
                        Rectangle {
                            width: 15
                            height: width
                            radius: width / 2
                            color: "#515151"
                            antialiasing: true
                            anchors.centerIn: parent
                        }
                    }

                    tickmarkLabel:  Text {
                        y: styleData.value === root.maxMotorKg ? 10 : (styleData.value === root.minMotorKg ? -10 : 0)
                        font.pixelSize: Math.max(10, root.diameter * 0.03)
                        text: styleData.value + ((styleData.value === root.maxMotorKg || styleData.value === root.minMotorKg) ? 'kg' : '')
                        font.bold: styleData.value >= (root.maxMotorKg - root.maxMotorKg * 0.2)
                        rotation: root.kgToAng(styleData.value)
                        color: styleData.value >= (root.maxMotorKg - root.maxMotorKg * 0.2) ? "#e34c22" : "black"
                        antialiasing: true
                    }


                    minorTickmark: Rectangle {
                        visible: false
                        implicitWidth: outerRadius * 0.01
                        antialiasing: true
                        implicitHeight: outerRadius * 0.03
                        color: "#e5e5e5"
                    }

                    tickmark: Rectangle {
                        //visible: styleData.value % labelStepSize == 0 ||
                        implicitWidth: outerRadius * 0.01
                        antialiasing: true
                        implicitHeight: implicitWidth * (styleData.value % (labelStepSize / 2) ? 3 : 6)
                        color: styleData.value >= (root.maxMotorKg - root.maxMotorKg * 0.2) ? "#e34c22" : "black"
                    }

                    needle: Rectangle {
                        antialiasing: true
                        width: outerRadius * 0.02
                        height: outerRadius * 0.7
                        color: "black"
                    }
                }
            }


            CircularGauge {
                anchors {
                    fill: parent;
                    margins: gaugeHeight * 0.1;
                }

                minimumValue: -20
                maximumValue: 20



                style: CircularGaugeStyle {
                    minimumValueAngle: 125 - 1
                    maximumValueAngle: 55 + 1
                    labelInset: 50

                    foreground: Item {
                        Rectangle {
                            width: 15
                            height: width
                            radius: width / 2
                            color: "#515151"
                            antialiasing: true
                            anchors.centerIn: parent
                        }
                    }



                    labelStepSize: 10

                    tickmarkLabel: Text {
                        color:"Black"
                        text : styleData.value
                    }





                    needle: Rectangle {

                        implicitWidth: outerRadius * 0.02
                        implicitHeight: outerRadius * 0.9
                        antialiasing: true
                        color: "red"
                    }
                }
            }

            Text {
                id: topBarText
                text: qsTr("Ololo")
                anchors.horizontalCenter: parent.horizontalCenter

                anchors.top: parent.top
                anchors.topMargin: root.gaugeHeight / 2
                font.pixelSize: 20
            }

            Text {
                id: bottomBarText
                text: root.speedMs
                anchors.horizontalCenter: parent.horizontalCenter

                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.gaugeHeight / 2
                font.pixelSize: 20
            }








            /*CircularGauge {
                width: parent.width
                height: parent.height



                style: CircularGaugeStyle {
                    needle: Rectangle {
                        y: outerRadius * 0.15
                        implicitWidth: outerRadius * 0.03
                        implicitHeight: outerRadius * 0.9
                        antialiasing: true
                        color: Qt.rgba(0.66, 0.3, 0, 1)
                    }
                }
            }*/

            /**
              Анимация
              */
            /*Rectangle {
                color: "lightgray"
                width: 200
                height: 200

                property int animatedValue: 0
                SequentialAnimation on animatedValue {
                    loops: Animation.Infinite
                    PropertyAnimation { to: 150; duration: 1000 }
                    PropertyAnimation { to: 0; duration: 1000 }
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.animatedValue
                }
            }*/
        }
    }



}
/*
Rectangle {
    height: 50
    property string message: "debug message"
    property var msgType: ["debug", "warning" , "critical"]
    color: "black"

    Column {
        anchors.fill: parent
        padding: 5.0
        spacing: 2
        Text {
            text: msgType.toString().toUpperCase() + ":"
            font.bold: msgType === "critical"
            font.family: "Terminal Regular"
            color: msgType === "warning" || msgType === "critical" ? "red" : "yellow"
            ColorAnimation on color {
                running: msgType === "critical"
                from: "red"
                to: "black"
                duration: 1000
                loops: msgType === "critical" ? Animation.Infinite : 1
            }
        }
        Text {
            text: message
            color: msgType === "warning" || msgType === "critical" ? "red" : "yellow"
            font.family: "Terminal Regular"
        }
    }

}*/
