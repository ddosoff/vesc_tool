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
    property real maxRopeMeters: 1500;

    property real power: 0
    property real maxPower: 20000
    property real minPower: maxPower * -1

    property real motorKg
    property real minMotorKg: 0
    property real maxMotorKg: 51

    property real tempFets: 0
    property real tempMotor: 0
    property real tempBat: 0

    property real whIn: 0
    property real whOut: 0

    property string motorMode: 'Not Connected'

    /********************
            Colors
    ********************/

    property real baseOpacity: 0.5  // Opacity is to all colors of the scale
    property string innerColor: '#efeded'
    property string gaugeDangerFontColor: '#8e1616' // Color for danger ranges
    property string gaugeFontColor: '#515151'
    property string gaugeColor: '#C7CFD9'

    // Default for all scales
    property string defaultColor: '#4CAF50' // base color (green)
    property string dangerColor: 'red'      // attention color (red)
    property string warningColor: '#FF9800' // blink color (yellow)

    property int gaugesColorAnimation: 800  // freq of blinking

    // Rope
    property string ropeColor: root.defaultColor
    property string ropeWarningColor: root.warningColor
    property string ropeDangerColor: root.dangerColor

    // MotorKg
    property string motorKgColor: root.defaultColor
    property string motorKgWarningColor: root.warningColor
    property string motorKgDangerColor: root.dangerColor

    // Power
    property string powerColor: root.defaultColor
    property string powerWarningColor: root.warningColor
    property string powerDangerColor: root.dangerColor

    // Speed
    property string speedColor: root.defaultColor
    property string speedWarningColor: root.warningColor
    property string speedDangerColor: root.dangerColor


    /********************
        Default view
    ********************/

    // Use minimum value
    property int diameter: width < height ? width : height
    implicitWidth: 200
    implicitHeight: 200

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
    property int animationDuration: 200
    property int animationType: Easing.OutExpo

    property real motorKgLabelStepSize: 5
    property real powerLabelStepSize: (maxPower - minPower) / (5 * 1000)

    /********************
         Do not touch
    ********************/
    property bool debug: false
    property bool debugBlink: false
    property bool motorKgWarning: false
    property bool motorKgDanger: false
    property bool ropeWarning: false
    property bool ropeDanger: false
    property bool powerWarning: false
    property bool powerDanger: false
    property bool speedWarning: false
    property bool speedDanger: false
    property int angK: 1000

    /********************/

    onMaxMotorKgChanged: root.setMaxMotorKg()
    onMaxRopeMetersChanged: setMaxRopeMeters()
    onMaxPowerChanged: root.setMaxPower()
    onMinPowerChanged: root.setMinPower()

    /********************/

    function setMaxRopeMeters() {
        root.maxRopeMeters = Math.ceil(parseInt(root.maxRopeMeters, 10) / 10) * 10;
    }

    function setMaxMotorKg() {
        root.maxMotorKg = Math.ceil(parseInt(root.maxMotorKg, 10) / 10) * 10;
        if (root.maxMotorKg > 20) {
            var  k = 10000 % root.maxMotorKg === 0 && root.maxMotorKg <= 50 ? 10 : 5;
            root.motorKgLabelStepSize = Math.ceil(parseInt(root.maxMotorKg, 10) / k / 10 ) * 10;
        } else {
            root.motorKgLabelStepSize = root.maxMotorKg / 5;
        }
    }

    function getPowerLimits(val) {
        val = Math.ceil(parseInt(Math.abs(val), 10) / 10000) * 10000;
        var step;

        if (val > 20000) {
            var  k = 10000000 % val === 0 && val <= 50000 ? 10 : 5;
            step = Math.ceil(parseInt(val, 10) / k / 10 ) * 10;
        } else {
            step = val / (2 * 1000);
        }

        return {val, step};
    }

    function setMaxPower() {
        var res = getPowerLimits(root.maxPower);
        root.maxPower = res.val;
        root.powerLabelStepSize = res.step;
    }

    function setMinPower() {
        var res = getPowerLimits(root.minPower);
        root.minPower = res.val * -1;
    }

    function prettyNumber(number, tf = 1) {
        if (!number || !!isNaN(number)) return 0;

        if (Math.abs(number) < 1 && number !== 0 && tf === 1) {
            tf = 2;
        } else if (Number.isInteger(number) && tf === 1) {
            tf = 0;
        }

        return parseFloat(number.toFixed(tf));
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

            Component.onCompleted: {
                root.setMaxMotorKg();
                root.setMaxPower();
                root.setMinPower();
                root.setMaxRopeMeters();
            }

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
                    property real ropeEndAng: ropeToAng(Math.max(root.maxRopeMeters - root.ropeMeters, root.minRopeMeters))

                    property real speedStartAng: speedToAng(0)
                    property real speedEndAng: speedToAng(Math.min(root.speedMs, root.maxSpeedMs))

                    property real motorKgStartAng: dl1.rotation - 90
                    property real motorKgEndAng: kgToAng(Math.min(root.motorKg, root.maxMotorKg))

                    property real powerStartAng: powerToAng(0)
                    property real powerEndAng: powerToAng(root.power > 0
                                                  ? Math.min(root.power, root.maxPower)
                                                  : Math.max(root.power, root.minPower))

                    property string ropeTextColor: 'black'
                    property string speedTextColor: 'black'
                    property string powerBgColor: 'black'
                    property string kgBgColor: 'black'

                    property bool ropeD: root.ropeDanger
                    property string ropeDColor: root.ropeDangerColor

                    property bool powerD: root.powerDanger
                    property string powerDColor: root.powerDangerColor

                    property bool motorKgD: root.motorKgDanger
                    property string motorKgDColor: root.motorKgDangerColor

                    property bool speedD: root.speedDanger
                    property string speedDColor: root.speedDangerColor

                    /*************** ROPE ***************/

                    onRopeDChanged: {
                        ropeDAnimation.loops = ropeD ? Animation.Infinite : 1;
                        if (!ropeD) ropeDColor = root.ropeDangerColor;
                        canvas.requestPaint();
                    }

                    onRopeDColorChanged: canvas.requestPaint()

                    ColorAnimation on ropeDColor {
                        id: ropeDAnimation
                        running: root.ropeDanger
                        from: root.ropeWarningColor
                        to: root.ropeDangerColor
                        duration: root.gaugesColorAnimation
                        loops: Animation.Infinite
                    }

                    /*************** POWER ***************/

                    onPowerDChanged: {
                        powerDAnimation.loops = powerD ? Animation.Infinite : 1;
                        if (!powerD) powerDColor = root.powerDangerColor;
                        canvas.requestPaint();
                    }

                    onPowerDColorChanged: canvas.requestPaint()

                    ColorAnimation on powerDColor {
                        id: powerDAnimation
                        running: root.powerDanger
                        from: root.powerWarningColor
                        to: root.powerDangerColor
                        duration: root.gaugesColorAnimation
                        loops: Animation.Infinite
                    }

                    /*************** KG ***************/

                    onMotorKgDChanged: {
                        motorKgDAnimation.loops = motorKgD ? Animation.Infinite : 1;
                        if (!motorKgD) motorKgDColor = root.motorKgDangerColor;
                        canvas.requestPaint();
                    }

                    onMotorKgDColorChanged: canvas.requestPaint()

                    ColorAnimation on motorKgDColor {
                        id: motorKgDAnimation
                        running: root.motorKgDanger
                        from: root.motorKgWarningColor
                        to: root.motorKgDangerColor
                        duration: root.gaugesColorAnimation
                        loops: Animation.Infinite
                    }

                    /*************** SPEED ***************/

                    onSpeedDChanged: {
                        speedDAnimation.loops = speedD ? Animation.Infinite : 1;
                        if (!speedD) speedDColor = root.speedDangerColor;
                        canvas.requestPaint();
                    }

                    onSpeedDColorChanged: canvas.requestPaint()

                    ColorAnimation on speedDColor {
                        id: speedDAnimation
                        running: root.speedDanger
                        from: root.speedWarningColor
                        to: root.speedDangerColor
                        duration: root.gaugesColorAnimation
                        loops: Animation.Infinite
                    }

                    /******************************/

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

                    /******************************/

                    onRopeEndAngChanged: {
                        if (root.debug && root.debugBlink) {
                            var debug = debugBlink(root.ropeMeters, root.maxRopeMeters);
                            root.ropeDanger = debug.danger;
                            root.ropeWarning = debug.warning;
                        }
                        canvas.requestPaint();
                        ropeCanvas.requestPaint();
                    }

                    onSpeedEndAngChanged: {
                        if (root.debug && root.debugBlink) {
                            var debug = debugBlink(root.speedMs, root.maxSpeedMs);
                            root.speedDanger = debug.danger;
                            root.speedWarning = debug.warning;
                        }
                        canvas.requestPaint();
                    }
                    onMotorKgEndAngChanged: {
                        if (root.debug && root.debugBlink) {
                            var debug = debugBlink(root.motorKg, root.maxMotorKg);
                            root.motorKgDanger = debug.danger;
                            root.motorKgWarning = debug.warning;
                        }
                        canvas.requestPaint();
                    }
                    onPowerEndAngChanged: {
                        if (root.debug && root.debugBlink) {
                            var debugMax = debugBlink(root.power, root.maxPower);
                            var debugMin = debugBlink(root.power, root.minPower);
                            root.powerDanger = root.power < 0 ? debugMin.danger : debugMax.danger;
                            root.powerWarning = root.power < 0 ? debugMin.warning : debugMax.warning;
                        }
                        canvas.requestPaint()
                    }

                    /******************************/

                    function debugBlink(value, max) {
                        var warningZone = 0.6 * Math.abs(max);
                        var dangerZone = 0.8 * Math.abs(max);
                        var warning;
                        var danger;

                        if (Math.abs(value) >= warningZone && Math.abs(value) < dangerZone) {
                            warning = true;
                            danger = false;
                        } else if (Math.abs(value) >= dangerZone) {
                            danger = true;
                            warning = false
                        } else {
                            warning = danger = false;
                        }

                        return { warning, danger };
                    }

                    function convertAngToRadian(ang) {
                        return (Math.PI * ang) / 180;
                    }

                    function drawTextAlongArc(context, str, centerX, centerY, radius, ang, color) {
                        var angle = (Math.PI * (str.length * 3.8)) / 180; // radians

                        context.save();
                        context.translate(centerX, centerY);
                        context.rotate(convertAngToRadian(ang) - angle / 2);

                        for (var n = 0; n < str.length; n++) {
                            var c = str[n];

                            context.rotate(angle / str.length);
                            context.save();
                            context.translate(0, -1 * radius);
                            context.fillStyle = color;
                            context.fillText(c, 0, 0);
                            context.restore();
                        }
                        context.restore();
                    }

                    function drawSpeedAlongArc(context, speed, centerX, centerY, radius) {
                        var str = '%1ms'.arg(speed);
                        var lc;

                        // Calculate angle of str
                        var angle = (Math.PI * (str.length * 3.8)) / 180; // radians

                        context.save();
                        context.translate(centerX, centerY);
                        context.rotate(convertAngToRadian(-180) - angle / 2);

                        //str = str.split("").reverse().join('');


                        for (var n = 0; n < str.length; n++) {
                            var c = str[n];
                            var d = c === 's' || c === 'm' ? -2 : 0;
                                d = lc === '.' ? 10 : d;

                            context.rotate(angle / (str.length + d));
                            context.save();
                            context.translate(0, -1 * radius);
                            context.fillStyle = c === '*' ? 'rgba(255, 0, 0, 0)' : progressBars.speedTextColor;
                            context.fillText(c, 0, 0);
                            context.restore();
                            lc = c;
                        }
                        context.restore();
                    }

                    function drawRopeAlongArc(context, lrm, rm, centerX, centerY, radius) {
                        var lrmLebgth = (lrm + '').replace('.', '').toString().length;
                        var rmLebgth = (rm + '').replace('.', '').toString().length;
                        var diff = lrmLebgth - rmLebgth;
                        var lc;

                        var str = '%1 |%2'
                            .arg(diff < 0 ? (((rm % 1) !== 0 ? '*' : '') + (new Array(Math.abs(diff) + 1).join('*')) + lrm + 'm') : (((rm % 1) !== 0 ? '*' : '') + lrm + 'm'))
                            .arg(diff > 0 ? (rm + 'm' + (new Array(Math.abs(diff) + 1).join('*'))) : (rm + 'm'));
                        //str = 'qqqqqq1111111qqqqqqqqqqqqqqsssssssssssqqqqqqqqqaaaaaaaaaq' + str + 'qqqqqq1111111qqqqqqqqqqqqqqsssssssssssqqqqqqqqqaaaaaaaaaq'

                        // Calculate angle of str
                        var angle = (Math.PI * (str.length * 3.8)) / 180; // radians



                        context.save();
                        context.translate(centerX, centerY);
                        context.rotate(convertAngToRadian(-5.5) - angle / 2);


                        for (var n = 0; n < str.length; n++) {
                            var c = str[n];
                            var d = c === 'm' ? -2 : 0;
                                d = lc === '.' ? 10 : d;

                            context.rotate(angle / (str.length + d));
                            context.save();
                            context.translate(0, -1 * radius);
                            context.fillStyle = c === '*' ? 'rgba(255, 0, 0, 0)' : progressBars.ropeTextColor;
                            context.fillText(c, 0, 0);
                            context.restore();
                            lc = c;
                        }
                        context.restore();
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

                                /********** BG ***********/

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


                                /********** Top | ROPE ***********/

                                var topEnd = parent.convertAngToRadian(parent.ropeEndAng - 90);
                                var topStart = parent.convertAngToRadian(parent.ropeStartAng + 90);

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

                                var b = root.ropeWarning || root.ropeDanger;
                                context.strokeStyle = b ? parent.ropeDColor : root.ropeColor;
                                context.stroke();


                                /********** Bottom | SPEED ***********/

                                var bottomStart = parent.convertAngToRadian(parent.speedStartAng - 90);
                                var bottomEnd = parent.convertAngToRadian(parent.speedEndAng - 90);

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

                                b = root.speedWarning || root.speedDanger;
                                parent.speedTextColor = b ? parent.speedDColor : 'black';
                                context.strokeStyle = b ? parent.speedDColor : root.speedColor;
                                context.stroke();


                                /********** Left | KG ***********/

                                var leftEnd = parent.convertAngToRadian(parent.motorKgStartAng + 180);
                                var leftStart = parent.convertAngToRadian(parent.motorKgEndAng - 180);

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

                                b = root.motorKgWarning || root.motorKgDanger;
                                motoKgTxt1.color = motoKgTxt2.color = b ? parent.motorKgDColor : 'black';
                                var kgColor = b ? parent.motorKgDColor : root.motorKgColor;

                                parent.kgBgColor = kgColor;
                                context.strokeStyle = kgColor;
                                context.stroke();


                                /*var gradient2 = context.createRadialGradient((parent.width / 2),(parent.height / 2), 0, (parent.width / 2),(parent.height / 2),parent.height);
                                gradient2.addColorStop(0.5, "#81FFFE");   //oben
                                gradient2.addColorStop(0.46, "#81FFFE");   //oben
                                gradient2.addColorStop(0.45, "#112478");   //mitte
                                gradient2.addColorStop(0.33, "transparent");   //unten
                                */

                                /********** Right | POWER ***********/

                                var rightEnd = parent.convertAngToRadian(parent.powerEndAng);
                                var rightStart = parent.convertAngToRadian(parent.powerStartAng);

                                context.beginPath();
                                context.arc(
                                    centreX,
                                    centreY,
                                    baseLayer.radius - root.gaugeHeight * 0.4,
                                    rightStart,
                                    rightEnd,
                                    (parent.powerEndAng - powerToAng(0)) < 0
                                );

                                context.lineWidth = root.gaugeHeight * 0.7;

                                b = root.powerWarning || root.powerDanger;
                                var powerColor = b ? parent.powerDColor : root.powerColor;
                                powerTxt2.color = powerTxt1.color = b ? parent.powerDColor : 'black';

                                parent.powerBgColor = powerColor;
                                context.strokeStyle = powerColor;
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
                                context.reset();
                                context.beginPath();

                                var centreX = baseLayer.width / 2;
                                var centreY = baseLayer.height / 2;

                                var topEnd = parent.convertAngToRadian(90 - dl1.rotation);
                                var topStart = parent.convertAngToRadian(90 - dl2.rotation);

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

                                topEnd = parent.convertAngToRadian(90 + dl2.rotation);
                                topStart = parent.convertAngToRadian(90 + dl1.rotation);

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

                Canvas {
                    id: ropeCanvas
                    antialiasing: true
                    contextType: '2d'
                    anchors.fill: parent

                    onWidthChanged:  { requestPaint(); }
                    onHeightChanged: { requestPaint(); }

                    onPaint: {
                        var centreX = baseLayer.width / 2;
                        var centreY = baseLayer.height / 2;

                        context.reset();
                        context.beginPath();
                        context.font = "%2 %1px sans-serif"
                            .arg(Math.max(10, root.diameter * 0.05))
                            .arg(root.boldValues ? 'bold' : '');

                        progressBars.drawRopeAlongArc(
                            context,
                            root.prettyNumber(root.leftRopeMeters, root.leftRopeMeters < 10 ? 1 : 0),
                            root.prettyNumber(root.ropeMeters, root.ropeMeters < 10 ? 1 : 0),
                            centreX,
                            centreY,
                            baseLayer.radius - root.gaugeHeight
                        );

                        context.beginPath();


                        /*progressBars.drawSpeedAlongArc(
                            context,
                            root.prettyNumber(root.speedMs),
                            centreX,
                            centreY,
                            baseLayer.radius - root.gaugeHeight
                        );*/

                        /*progressBars.drawTextAlongArc(
                            context,
                            'Rope',
                            centreX,
                            centreY,
                            baseLayer.radius - root.gaugeHeight,
                            180 -  90 - dl2.rotation,
                            '#515151'
                        );*/
                    }
                }

                /*Canvas {
                    id: speedCanvas
                    antialiasing: true
                    contextType: '2d'
                    anchors.fill: parent


                    onWidthChanged:  { requestPaint(); }
                    onHeightChanged: { requestPaint(); }



                    onPaint: {

                        var centreX = baseLayer.width / 2;
                        var centreY = baseLayer.height / 2;

                        context.reset();
                        context.beginPath();
                        context.font = "%1px sans-serif".arg(Math.max(10, root.diameter * 0.05));



                        context.beginPath();

                        /*progressBars.drawTextAlongArc(
                            context,
                            'Rope',
                            centreX,
                            centreY,
                            baseLayer.radius - root.gaugeHeight,
                            180 -  90 - dl2.rotation,
                            '#515151'
                        );
                    }
                }*/

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

                    function getTLHY(value, min, max, k = 0.3) {
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
                                    return root.prettyNumber(styleData.value) + ((styleData.value === root.minMotorKg) ? 'kg' : '');
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
                                implicitWidth: outerRadius * 0.01
                                implicitHeight:  (styleData.value === root.maxMotorKg || styleData.value === root.minMotorKg)
                                    ? root.gaugeHeight * 1.7
                                    : implicitWidth * (styleData.value % (root.motorKgLabelStepSize / 2) ? 3 : 6)
                                color: root.gaugeFontColor
                            }

                            /**
                              Needle
                            */
                            needle: Rectangle {
                                visible: root.motorKg !== root.minMotorKg
                                antialiasing: true
                                width: outerRadius * 0.01
                                height: outerRadius
                                color: progressBars.kgBgColor
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

                        minimumValue: root.minPower / 1000
                        maximumValue: root.maxPower / 1000
                        value: root.power / 1000

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

                            foreground: null
                            minorTickmark: null

                            tickmarkLabel:  Text {
                                font.pixelSize: gauge.getFontSize()
                                y: gauge.getTLHY(styleData.value * 1000, root.minPower, root.maxPower)
                                x: gauge.getTLHX(styleData.value * 1000, root.minPower, root.maxPower, -0.13)
                                text: styleData.value + ((styleData.value === 0) ? 'kw' : '')
                                rotation: root.powerToAng(styleData.value * 1000)
                                color: gauge.getTLColor(Math.abs(styleData.value * 1000), root.maxPower)
                                antialiasing: true
                                font.family: root.ff
                            }


                            tickmark: Rectangle {
                                antialiasing: true
                                implicitWidth: outerRadius * 0.01
                                implicitHeight:  (styleData.value * 1000 === root.maxPower || styleData.value * 1000 === root.minPower)
                                    ? root.gaugeHeight * 1.7
                                    : implicitWidth * ((styleData.value % (root.powerLabelStepSize)) ? 3 : 6)
                                color: root.gaugeFontColor
                            }

                            needle: Rectangle {
                                visible: root.power !== 0
                                color: progressBars.powerBgColor
                                antialiasing: true
                                width: outerRadius * 0.01
                                height: outerRadius
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

                            foreground: null
                            minorTickmark: null

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
                            labelStepSize: 1

                            foreground: null
                            minorTickmark: null
                            needle: null


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


                            tickmark: Rectangle {
                                function show(value) {
                                    var ifHalf = value === Math.ceil((root.maxRopeMeters / 2));
                                    var ifQuat1 = value === Math.ceil((root.maxRopeMeters / 4));
                                    var ifQuat2 = value === Math.ceil((root.maxRopeMeters - root.maxRopeMeters / 4));
                                    return ifHalf || ifQuat1 || ifQuat2;
                                }

                                visible: this.show(styleData.value)
                                antialiasing: true
                                implicitWidth: outerRadius * ((styleData.value === root.maxRopeMeters || styleData.value === root.minRopeMeters)
                                    ? 0.005
                                    : 0.01)
                                implicitHeight:  (styleData.value === root.maxRopeMeters || styleData.value === root.minRopeMeters)
                                    ? root.gaugeHeight
                                    : implicitWidth * ((styleData.value % (root.maxRopeMeters)) ? 3 : 6)
                                color: root.gaugeFontColor
                            }


                        }
                    }
                }
                Canvas {
                    //opacity: 0.5
                    antialiasing: true
                    contextType: '2d'
                    anchors.fill: parent
                    onPaint: {
                        if (context) {
                            context.reset();
                            context.beginPath();

                            var centreX = baseLayer.width / 2;
                            var centreY = baseLayer.height / 2;

                            /**   Right   **/
                            var topEnd = progressBars.convertAngToRadian(90 - dl1.rotation);
                            var topStart = progressBars.convertAngToRadian(90 - dl2.rotation);

                            context.beginPath();
                            context.moveTo(centreX, centreY);
                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius - root.gaugeHeight * 1.7,
                                topStart - progressBars.convertAngToRadian(20),
                                topEnd + progressBars.convertAngToRadian(20),
                                false
                            );

                            context.lineTo(centreX, centreY);
                            context.fillStyle = root.innerColor;
                            context.fill();

                            context.beginPath();

                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius - root.gaugeHeight * 1.7,
                                topStart,
                                topEnd,
                                false
                            );

                            context.lineWidth = 2;
                            context.strokeStyle = root.borderColor;
                            context.stroke();

                            /**   Left   **/
                            topEnd = progressBars.convertAngToRadian(90 + dl2.rotation);
                            topStart = progressBars.convertAngToRadian(90 + dl1.rotation);

                            context.beginPath();
                            context.moveTo(centreX, centreY);
                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius - root.gaugeHeight * 1.7,
                                topStart - progressBars.convertAngToRadian(20),
                                topEnd + progressBars.convertAngToRadian(20),
                                false
                            );

                            context.lineTo(centreX, centreY);
                            context.fillStyle = root.innerColor;
                            context.fill();

                            context.beginPath();

                            context.arc(
                                centreX,
                                centreY,
                                baseLayer.radius - root.gaugeHeight * 1.7,
                                topStart,
                                topEnd,
                                false
                            );

                            context.lineWidth = 2;
                            context.strokeStyle = root.borderColor;
                            context.stroke();
                        }
                    }
                }

                /**
                  Center point
                  */
                Rectangle {
                    anchors.horizontalCenter: baseLayer.horizontalCenter
                    anchors.verticalCenter: baseLayer.verticalCenter
                    width: 5
                    height: width
                    radius: 50
                    color: root.borderColor
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
                        font.pixelSize: Math.max(10, root.diameter * 0.05)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }

                    Text {
                        text: 'ms'
                        font.pixelSize: Math.max(10, root.diameter * 0.05)
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
                    anchors.topMargin: root.gaugeHeight * 3.3
                    font.pixelSize: Math.max(10, root.diameter * 0.055)
                    font.family: root.ff
                }

                /**
                  Value of motorKg
                  */
                Grid {
                    anchors.verticalCenter: parent.verticalCenter
                    //anchors.horizontalCenter: parent.horizontalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: root.gaugeHeight * 2.5
                    spacing: 5

                    Text {
                        id: motoKgTxt1
                        text: root.prettyNumber(root.motorKg, root.motorKg >= 25 ? 0 : 1)
                        font.pixelSize: Math.max(10, root.diameter * 0.07)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }

                    Text {
                        id: motoKgTxt2
                        text: 'kg'
                        opacity: 0.8
                        font.pixelSize: Math.max(10, root.diameter * 0.07)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }
                }

                /**
                  Value of power
                  */
                Grid {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: root.gaugeHeight * 2.5
                    spacing: 5

                    Text {
                        id: powerTxt1
                        text: root.prettyNumber(Math.abs(root.power) >= 100 ? root.power / 1000 : root.power, Math.abs(root.power) < 100 ? 0 : 1)
                        font.pixelSize: Math.max(10, root.diameter * 0.07)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }

                    Text {
                        id: powerTxt2
                        text: Math.abs(root.power) >= 100 ? 'kw' : 'w'
                        opacity: 0.8
                        font.pixelSize: Math.max(10, root.diameter * 0.07)
                        font.family: root.ff
                        font.bold: root.boldValues
                    }
                }

                Grid {

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.gaugeHeight * 3.4
                    columns: 6
                    spacing: 5
                    width: root.diameter * 0.5

                    Item {
                        width: 20
                        height: 30
                        Image {
                            id: tfetsIco
                            smooth: true
                            source: "qrc:/res/icons/motor.svg"
                            sourceSize.width: 26
                            sourceSize.height: 34
                            y: -1
                            visible: false

                        }
                        ColorOverlay {
                            anchors.fill: tfetsIco
                            source: tfetsIco
                            color: Material.color(Material.Blue)
                        }
                    }

                    Item {
                        width: 25
                        height: 25

                        Text {
                            text: 55 + 'C'
                            color: 55 > 80 ? "red" : systemPalette.text;
                        }
                    }



                    Item {
                        width: 20
                        height: 25

                        Image {
                            id: tmotIco
                            smooth: true
                            source: "qrc:/res/icons/mcu.svg"
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
                        width: 25
                        height: 25

                        Text {
                            text: 55 + 'C'
                            color: 55 > 80 ? "red" : systemPalette.text;
                        }
                    }



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
                        width: 25
                        height: 25

                        Text {
                            text: 55 + 'C'
                            color: 55 > 80 ? "red" : systemPalette.text;
                        }
                    }

                }


                /*Item {

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.gaugeHeight * 4

                    Rectangle {
                        id: inWh
                        height: 20
                        x: (lol.width  + inArrow.width + 15) * -1
                        width: inWhT.width
                        color: "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            id: inWhT
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            text: "%1Wh".arg((3.5).toFixed(1))
                        }

                    }

                    Rectangle {
                        id: inArrow
                        height: 20
                        x: -lol.width + 10
                        width: inArrowT.width
                        color: "transparent"

                        Text {
                            id: inArrowT
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            font.bold: true
                            text: '>>'
                            color: 'red';
                        }
                    }

                    Rectangle {
                        id: lol
                        width: tBat.width + 20
                        height: 20
                        border.color: 'grey'
                        x: -lol.width / 2
                        radius: 3

                        Rectangle {
                            anchors.left: lol.left
                            anchors.leftMargin: 1
                            anchors.verticalCenter: lol.verticalCenter


                            height: lol.height-2
                            color: "lightgreen"
                            width: lol.width * 33 / 100
                        }

                        Text {
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            id: tBat
                            anchors.centerIn: parent
                            text: qsTr("%2x6").arg((1.11).toFixed(2))
                        }

                        Rectangle {
                            anchors.left: lol.right
                            anchors.verticalCenter: lol.verticalCenter

                            height: 10
                            width: 2
                            border.color: 'grey'

                        }
                    }


                    Rectangle {
                        id: outArrow
                        height: 20
                        x: lol.width / 2 + 5
                        width: outArrowT.width
                        color: "transparent"

                        Text {
                            id: outArrowT
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            font.bold: true
                            text: '>>'
                            color: 'red';
                        }
                    }

                    Rectangle {
                        id: outWh
                        height: 20
                        x: lol.width / 2 + outArrow.width + 10
                        width: outWhT.width
                        color: "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            id: outWhT
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            text: "%1Wh".arg((3.5).toFixed(1))
                        }

                    }
                }*/
            }
        }

        Rectangle {
            width: parent.width
            height: 300

            visible: root.debug

            Grid {
                columns: 4
                anchors.fill: parent
                spacing: 10

                Column {
                    spacing: 10

                    Slider {
                        id: qwd
                        minimumValue: 0
                        maximumValue: 1
                        stepSize: 1
                        value: 0

                        onValueChanged: {
                            root.ropeDanger = !!value;
                        }
                    }

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
                            Layout.fillWidth: true

                            onValueChanged: {
                                var res = kgToAng(value);
                                root.motorKg = value;
                            }
                        }
                    }

                    Column {
                        spacing: 5

                        Text {
                            text: 'MaxKg'
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Slider {

                            minimumValue: 0
                            maximumValue: 200
                            value: root.maxMotorKg

                            onValueChanged: {
                                root.maxMotorKg = value;
                            }
                        }

                        Text {
                            text: 'Kg step'
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Slider {

                            minimumValue: 1
                            maximumValue: 20
                            value: root.motorKgLabelStepSize

                            onValueChanged: {
                                root.motorKgLabelStepSize = value;
                            }
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
                            root.power = value;
                        }
                    }

                    Text {
                        text: 'Power step'
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Slider {

                        minimumValue: 1
                        maximumValue: 20
                        value: root.powerLabelStepSize

                        onValueChanged: {
                            root.powerLabelStepSize = parseInt(value);
                        }
                    }

                    Text {
                        text: 'Power max'
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Slider {
                        minimumValue: 0
                        maximumValue: 100000
                        value: root.maxPower

                        onValueChanged: {
                            root.maxPower = value;
                        }
                    }

                    Slider {
                        minimumValue: -100000
                        maximumValue: 0
                        value: root.minPower

                        onValueChanged: {
                            root.minPower = value;
                        }
                    }
                }
            }
        }
    }
}
