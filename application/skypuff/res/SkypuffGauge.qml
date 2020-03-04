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
    property real acceleration: 5
    property real maxSpeedMs: 20
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

    property string motorMode: 'Not Connected'
    property string state: 'DISCONNECTED'
    property string stateText: 'Disconnected'
    property string status
    property string fault

    property bool isWarningStatus: false

    property real batteryPercents: 0
    property real batteryCellVolts: 0.0
    property int batteryCells: 0

    property real whIn: 0.0
    property real whOut: 0.0

    property bool isBatteryBlinking: false
    property bool isBatteryWarning: false
    property bool isBatteryScaleValid: false

    property bool showCharginAnimation: false

    property string ff: 'Roboto'


    /********************
            Colors
    ********************/

    property real baseOpacity: 1  // Opacity is to all colors of the scale

    property string gaugeDangerFontColor: '#8e1616' // Color for danger ranges
    property string gaugeFontColor: '#374759'
    property string gaugeColor: '#dfe3e8'
    property string battGaugeColor: '#dfe3e8'
    property string textColor: 'black'
    property string borderColor: '#737E8C'      // Color of all borders
    property string borderGlowColor: '#C7CFD9'
    property string color: '#F7F7F7'            // Main backgroundColor
    property string innerColor: color


    // Default for all scales
    property string defaultColor: '#A5D6A7'  // base succes color
    property string dangerColor: '#ef8383'   // attention color
    property string dangerTextColor: '#F44336'
    property string warningColor: '#dbdee3'  // blink color
    property int gaugesColorAnimation: 1000  // freq of blinking

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

    // Battery
    property string battColor: root.defaultColor
    property string battWarningColor: root.warningColor
    property string battDangerColor: root.dangerColor


    /********************
        Default view
    ********************/

    property int rootDiameter: 200
    property int paddingLeft: 20
    property int paddingRight: 20
    property int marginTop: 20
    property int batteryTopMargin: 20

    property int diameter: rootDiameter - paddingLeft - paddingRight

    implicitWidth: diameter
    implicitHeight: diameter + (batteryBlock.height) + marginTop + batteryTopMargin

    property int diagLAnc: 55                   // Angle of diagonal lines from 12 hours

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

    onStatusChanged: {
        status.text = root.status;
        status.color = root.isWarningStatus ? root.dangerTextColor : root.textColor;

        statusCleaner.restart();
        faultsBlinker.stop();
    }

    onFaultChanged:  {
        status.text = root.fault;
        faultsBlinker.start();

    }

    onMaxMotorKgChanged: root.setMaxMotorKg();
    onMaxRopeMetersChanged: setMaxRopeMeters();
    onMaxPowerChanged: root.setMaxPower();
    onMaxSpeedMsChanged: root.getSpeedLimit();
    onMinSpeedMsChanged: root.getSpeedLimit();
    onMinPowerChanged: root.setMinPower();
    onAccelerationChanged: speedCanvas.requestPaint();

    /********************/

    function getWhValStr(val) {
        if (val >= 1000) {
            return prettyNumber(val / 1000) + ' kwh';
        }

        return prettyNumber(val) + ' wh';
    }

    function setMaxRopeMeters() {
        root.maxRopeMeters = Math.ceil(parseInt(root.maxRopeMeters, 10) / 10) * 10;
    }

    function setMaxMotorKg() {
        var s = root.maxMotorKg <= 10 ? 2 : 10
        root.maxMotorKg = Math.ceil(parseInt(root.maxMotorKg, 10) / s) * s;

        if (root.maxMotorKg > 20) {
            var  k = 10000 % root.maxMotorKg === 0 && root.maxMotorKg <= 50 ? 10 : 5;
            root.motorKgLabelStepSize = Math.ceil(parseInt(root.maxMotorKg, 10) / k / 10 ) * 10;
        } else if (root.maxMotorKg < 10) {
            root.motorKgLabelStepSize = 2;
        } else {
            root.motorKgLabelStepSize = root.maxMotorKg / 5;
        }
    }

    function getSpeedLimit() {
        root.maxSpeedMs = Math.ceil(parseInt(Math.abs(root.maxSpeedMs), 10) / 10) * 10;
        root.minSpeedMs = root.maxSpeedMs * -1;
    }

    function getPowerLimits(val) {
        var k = 1000;
        var res = Math.ceil(parseInt(Math.abs(val), 10) / k) * k;

        // Getting rid of bad numbers.
        // For example: 14k is a bad number because in range 2k-6k it divides only by 2k and by itself
        if (isPrime(res, 1000)) {
            res += 2000;
        }

        return res;
    }

    function isPrime(num, k = 1) {
      if (num === 2 * k) return false;

      for (var i = 3 * k; i <= 6 * k; i += 1 * k) {
        if (num % i === 0) return false;
      }
      return true;
    }

    function getDivider(val, maxStep, k = 1) {
        var step = 2;
        for (var d = 2; d <= maxStep; d++) {
            if (val % (d * k)  === 0) step = d;
        }

        return step;
    }

    function getPowerStep() {
        var step;

        var diff = root.maxPower + Math.abs(root.minPower);
        var power = Math.abs(root.minPower);

        // Looking for the maximum possible step
        step = getDivider(power, 5, 1000);

        // If gauge divided more than 6 part
        if (diff / (step * 1000)  > 6) {
            step = getDivider(power, 10, 1000);
        }

        // Custom steps
        if (diff <= 10000) step = 2;
        if (diff <= 4000) step = 1;

        return parseInt(step, 10);
    }

    function setMaxPower() {
        root.maxPower = getPowerLimits(root.maxPower);
        root.powerLabelStepSize = getPowerStep();
    }

    function setMinPower() {
        root.minPower = getPowerLimits(root.minPower) * -1;
        root.powerLabelStepSize = getPowerStep();
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
        return (value === root.minPower ? res + 0.1 : res);
    }

    Item {
        id: gaugeBlock
        width: diameter
        height: diameter

        Component.onCompleted: {
            root.setMaxMotorKg();
            root.setMaxPower();
            root.setMinPower();
            root.getSpeedLimit();
            root.setMaxRopeMeters();
        }

        RectangularGlow {
            id: effect
            anchors.fill: baseLayer
            glowRadius: 10
            spread: 0
            color: root.borderGlowColor
            cornerRadius: baseLayer.radius + glowRadius
        }

        Rectangle {
            id: baseLayer
            width: root.diameter
            height: root.diameter
            radius: root.diameter / 2
            color: root.color
            border.color: root.borderColor
            border.width: 3
            x: root.paddingLeft
            y: root.marginTop

            layer.enabled: true
            layer.effect: Glow {
                samples: 15
                color: root.borderGlowColor
                transparentBorder: true
            }

            /**
              2 diagonal lines
              */
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

                property string ropeTextColor: root.textColor
                property string speedTextColor: root.textColor
                property string powerBgColor: root.textColor
                property string kgBgColor: root.textColor

                property bool ropeD: root.ropeDanger
                property bool ropeW: root.ropeWarning
                property string ropeDColor: root.ropeDangerColor

                property bool powerD: root.powerDanger
                property bool powerW: root.powerWarning
                property string powerDColor: root.powerDangerColor

                property bool motorKgD: root.motorKgDanger
                property bool motorKgW: root.motorKgWarning
                property string motorKgDColor: root.motorKgDangerColor

                property bool speedD: root.speedDanger
                property bool speedW: root.speedWarning
                property string speedDColor: root.speedDangerColor

                /*************** ROPE ***************/

                onRopeDChanged: {
                    // Count of loops
                    ropeDAnimation.loops = ropeD ? Animation.Infinite : 1;
                    // Restore default color
                    if (!ropeD) ropeDColor = root.ropeDangerColor;
                    canvas.requestPaint();
                }

                onRopeWChanged: canvas.requestPaint()
                onRopeDColorChanged: canvas.requestPaint()

                ColorAnimation on ropeDColor {
                    id: ropeDAnimation
                    running: root.ropeDanger
                    from: root.ropeDangerColor
                    to: root.ropeWarningColor
                    duration: root.gaugesColorAnimation
                    loops: Animation.Infinite // Loops will be controlled in onRopeDChanged
                }

                /*************** POWER ***************/

                onPowerDChanged: {
                    powerDAnimation.loops = powerD ? Animation.Infinite : 1;
                    if (!powerD) powerDColor = root.powerDangerColor;
                    canvas.requestPaint();
                }

                onPowerWChanged: canvas.requestPaint()
                onPowerDColorChanged: canvas.requestPaint()

                ColorAnimation on powerDColor {
                    id: powerDAnimation
                    running: root.powerDanger
                    from: root.powerDangerColor
                    to: root.powerWarningColor
                    duration: root.gaugesColorAnimation
                    loops: Animation.Infinite
                }

                /*************** KG ***************/

                onMotorKgDChanged: {
                    motorKgDAnimation.loops = motorKgD ? Animation.Infinite : 1;
                    if (!motorKgD) motorKgDColor = root.motorKgDangerColor;
                    canvas.requestPaint();
                }

                onMotorKgWChanged: canvas.requestPaint()
                onMotorKgDColorChanged: canvas.requestPaint()

                ColorAnimation on motorKgDColor {
                    id: motorKgDAnimation
                    running: root.motorKgDanger
                    from: root.motorKgDangerColor
                    to: root.motorKgWarningColor
                    duration: root.gaugesColorAnimation
                    loops: Animation.Infinite
                }

                /*************** SPEED ***************/

                onSpeedDChanged: {
                    speedDAnimation.loops = speedD ? Animation.Infinite : 1;
                    if (!speedD) speedDColor = root.speedDangerColor;
                    canvas.requestPaint();
                }

                onSpeedWChanged: canvas.requestPaint()
                onSpeedDColorChanged: canvas.requestPaint()

                ColorAnimation on speedDColor {
                    id: speedDAnimation
                    running: root.speedDanger
                    from: root.speedDangerColor
                    to: root.speedWarningColor
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
                        // Only for debug
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
                    speedCanvas.requestPaint();
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
                    var warning  = false;
                    var danger = false;

                    if (Math.abs(value) >= warningZone && Math.abs(value) < dangerZone) {
                        warning = true;
                        danger = false;
                    } else if (Math.abs(value) >= dangerZone) {
                        danger = true;
                        warning = false
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

                function drawRopeAlongArc(context, lrm, rm, centerX, centerY, radius) {
                    lrm += 'm';
                    rm += 'm';

                    // Calculate width angle of str
                    var angle = (Math.PI * (lrm.length * 3.8)) / 180; // radians

                    context.save();
                    context.translate(centerX, centerY);

                    // -11.2 - margin

                    var marginAng = lrm.indexOf('.') !== -1 ? -10 : -11.2
                    context.rotate(convertAngToRadian(marginAng) - angle);
                    drawArc(context, lrm.toString(), angle, radius);
                    context.restore();

                    /******/

                    angle = (Math.PI * (rm.length * 3.8)) / 180; // radians
                    context.save();
                    context.translate(centerX, centerY);
                    drawArc(context, rm.toString(), angle, radius);
                    context.restore();

                    /******/

                    angle = 0 // radians
                    context.save();
                    context.translate(centerX, centerY);
                    context.rotate(convertAngToRadian(-1));
                    drawArc(context, '|', angle, radius);
                    context.restore();
                }

                function drawSpeedAlongArc(context, speed, acceleration, centerX, centerY, radius) {
                    speed += 'ms';
                    speed = speed.split("").reverse().join("");
                    acceleration += 'ms2';
                    acceleration = acceleration.split("").reverse().join("");

                    // Calculate width angle of str
                    var angle = (Math.PI * (speed.length * 3.8)) / 180; // radians

                    context.save();
                    context.translate(centerX, centerY);

                    // -11.2 - margin

                    var marginAng = (speed.indexOf('.') !== -1 ? -8.2 : -7) + 180
                    context.rotate(convertAngToRadian(marginAng) - angle);
                    drawArc(context, acceleration.toString(), angle, radius, true);

                    context.restore();

                    /******/

                    angle = (Math.PI * (acceleration.length * 3.8)) / 180; // radians

                    context.save();
                    context.translate(centerX, centerY);

                    marginAng = (acceleration.indexOf('.') !== -1 ? -6.4 : -6)
                    context.rotate(convertAngToRadian(180 + marginAng) + angle);
                    drawArc(context, speed.toString(), angle, radius, true);
                    context.restore();

                    /******/

                    angle = convertAngToRadian(180) // radians
                    context.save();
                    context.translate(centerX, centerY);
                    context.rotate(convertAngToRadian(-1));
                    drawArc(context, '|', angle, radius);
                    context.restore();
                }

                function drawArc(context, str, angle, radius, reverse = false) {
                    var lc;
                    for (var n = 0; n < str.length; n++) {
                        var c = str[n];

                        // blyadskij cirk
                        var a;

                        if (reverse) {
                            a = lc === 's' ? -2.4 : 0;
                            a = lc === '.' ? -1 : a;
                        } else {
                            a = c === 'm' ? -1.2 : 0;
                            a = lc === '.' ? 1.2 : a;
                        }

                        context.rotate(angle / (str.length) - convertAngToRadian(a));
                        //console.log(angle / (str.length) - convertAngToRadian(a))
                        context.save();
                        //console.log(radius)
                        context.translate(0, -1 * radius);

                        if (reverse) {

                            var cx = context.measureText(c).width ;

                            context.scale(-1, -1, 0, 0);
                            context.translate(0, Math.max(10, root.diameter * 0.05) / 2);

                        }

                        context.fillStyle = progressBars.speedTextColor;
                        context.fillText(c, 0, 0);
                        context.restore();
                        lc = c;
                    }
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
                            parent.speedTextColor = b ? parent.speedDColor : root.textColor;
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
                            motoKgTxt1.color = motoKgTxt2.color = b ? root.dangerTextColor : root.textColor;
                            var kgColor = b ? parent.motorKgDColor : root.motorKgColor;

                            parent.kgBgColor = kgColor;
                            context.strokeStyle = kgColor;
                            context.stroke();


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
                            powerTxt2.color = powerTxt1.color = b ? root.dangerTextColor : root.textColor;

                            parent.powerBgColor = powerColor;
                            context.strokeStyle = powerColor;
                            context.stroke();
                        }
                    }
                }

                /**
                  Left and Rigth BG
                 */
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

            /**
              Text along arc
              */
            Canvas {
                id: ropeCanvas
                antialiasing: true
                contextType: '2d'
                anchors.fill: parent

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
                }
            }

            Canvas {
                id: speedCanvas
                antialiasing: true
                contextType: '2d'
                anchors.fill: parent

                onPaint: {
                    var centreX = baseLayer.width / 2;
                    var centreY = baseLayer.height / 2;

                    context.reset();
                    context.beginPath();
                    context.font = "%2 %1px sans-serif"
                        .arg(Math.max(10, root.diameter * 0.05))
                        .arg(root.boldValues ? 'bold' : '');

                    progressBars.drawSpeedAlongArc(
                        context,
                        root.prettyNumber(root.speedMs),
                        root.prettyNumber(root.acceleration),
                        centreX,
                        centreY,
                        baseLayer.radius - root.gaugeHeight
                    );

                    context.beginPath();
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

            /**
              Gauges
              */
            Item {
                id: gauge

                anchors {
                    fill: parent
                    //margins: gaugeHeight * 0.1
                    margins: baseLayer.border.width
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

                        tickmarkStepSize: root.maxMotorKg < 10 ? 2 : 5

                        /**
                          Center point
                        */
                        foreground: null

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
                            font.family: root.ff
                            text: this.getText()
                            rotation: root.kgToAng(styleData.value)
                            antialiasing: true
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
                            implicitHeight: (styleData.value === root.maxMotorKg || styleData.value === root.minMotorKg)
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
                            color: Qt.darker(progressBars.kgBgColor, 1.4)
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
                        labelStepSize: root.powerLabelStepSize * 1000
                        tickmarkStepSize: 100

                        foreground: null
                        minorTickmark: null

                        tickmarkLabel:  Text {
                            font.pixelSize: gauge.getFontSize()
                            font.family: root.ff
                            y: gauge.getTLHY(styleData.value , root.minPower, root.maxPower)
                            x: gauge.getTLHX(styleData.value , root.minPower, root.maxPower, -0.13)
                            text: (styleData.value / 1000)  + ((styleData.value === 0) ? 'kw' : '')
                            rotation: root.powerToAng(styleData.value )
                            color: gauge.getTLColor(Math.abs(styleData.value), root.maxPower)
                            antialiasing: true
                        }

                        tickmark: Rectangle {
                            visible: styleData.value % ((root.maxPower + Math.abs(root.minPower)) > 30000 ? 2000 : 1000) === 0
                            antialiasing: true
                            implicitWidth: outerRadius * 0.01
                            implicitHeight:  (styleData.value  === root.maxPower || styleData.value  === root.minPower)
                                ? root.gaugeHeight * 1.7
                                : implicitWidth * ((styleData.value % (root.powerLabelStepSize * 1000)) ? 3 : 6)
                            color: root.gaugeFontColor
                        }

                        needle: Rectangle {
                            visible: root.power !== 0
                            color: Qt.darker(progressBars.powerBgColor, 1.4)
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
                            font.family: root.ff
                            text: styleData.value + ((styleData.value === 0) ? 'kw' : '')
                            rotation: styleData.value !== root.maxSpeedMs ? root.speedToAng(styleData.value) - 180 - 90 : root.speedToAng(styleData.value)  - 90
                            color: root.gaugeFontColor
                            antialiasing: true
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

                        needle: null
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
                            font.family: root.ff
                            font.pixelSize: gauge.getFontSize(0.04)
                            y: gauge.getTLVY(styleData.value, root.minRopeMeters, root.maxRopeMeters, -0.3)
                            x: gauge.getTLVX(styleData.value, root.minRopeMeters, root.maxRopeMeters, -0.3)
                            text: styleData.value + ((styleData.value === 0) ? 'm' : '')
                            rotation: this.getAng(styleData.value)
                            color: root.gaugeFontColor
                            antialiasing: true
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

            /**
              Right and Left BG borders
              */
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
                color: root.innerColor
            }

            /**
              Value of speedMs
              */
            /*Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.gaugeHeight / 1.7
                spacing: 5

                Text {
                    text: root.prettyNumber(root.speedMs)
                    font.family: root.ff
                    font.pixelSize: Math.max(10, root.diameter * 0.05)
                    font.bold: root.boldValues
                }

                Text {
                    text: 'm/s'
                    font.family: root.ff
                    font.pixelSize: Math.max(10, root.diameter * 0.05)
                    font.bold: root.boldValues
                }
            }*/

            /**
              State
              */
            Text {
                id: state
                text: root.stateText
                font.family: root.ff
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                antialiasing: true
                font.pixelSize: Math.max(10, root.diameter * 0.06)
                color: root.state === "MANUAL_BRAKING" ? root.dangerTextColor : root.textColor;

                property real mDown: root.gaugeHeight * 2.8

                states: [
                    State {
                        name: "up"
                        when: !!status.text
                        PropertyChanges {
                          target: state
                          anchors.topMargin: state.mDown - (statusHeight.height < status.height ? status.height / 2 : 0)
                        }
                    },
                    State {
                        name: "down"
                        when: !status.text
                        PropertyChanges {
                          target: state
                          anchors.topMargin: state.mDown
                        }
                    }
                ]

                transitions: [
                    Transition {
                        to: "up"
                        NumberAnimation {
                            properties: 'anchors.topMargin';
                            easing.type: Easing.OutExpo;
                            duration: 50
                        }
                    },
                    Transition {
                        to: "down"
                        NumberAnimation {
                            properties: 'anchors.topMargin';
                            easing.type: Easing.OutExpo;
                            duration: 80
                        }
                    }
                ]
            }

            Text {
                id: statusHeight
                text: 'status'

                anchors.horizontalCenter: parent.horizontalCenter
                font.letterSpacing: 0.7
                font.family: root.ff
                anchors.top: parent.top
                anchors.topMargin: root.gaugeHeight * 4.7 - status.height
                font.pixelSize: Math.max(10, root.diameter * 0.038)
                color: 'transparent'
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            /**
              Status
              */
            Text {
                id: status
                text: root.status
                visible: !!root.status
                anchors.horizontalCenter: parent.horizontalCenter
                font.letterSpacing: 0.7
                font.family: root.ff
                width: root.diameter * 0.5
                //font.bold: true
                anchors.top: parent.top
                anchors.topMargin: root.gaugeHeight * 4.55 - status.height
                font.pixelSize: Math.max(10, root.diameter * 0.038)
                color:  Qt.lighter(root.textColor);
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter


                SequentialAnimation on color {
                    id: faultsBlinker
                    loops: Animation.Infinite
                    ColorAnimation { easing.type: Easing.OutExpo; from: root.textColor; to: root.dangerTextColor; duration: 400 }
                    ColorAnimation { easing.type: Easing.OutExpo; from: root.dangerTextColor; to: root.textColor;  duration: 200 }
                }

                Timer {
                    id: statusCleaner
                    interval: 5 * 1000

                    onTriggered: {
                        status.text = root.status

                        if(root.fault) {
                            faultsBlinker.start();
                        } else {
                            faultsBlinker.stop();
                        }
                    }
                }
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
                    font.family: root.ff
                    text: root.prettyNumber(root.motorKg, root.motorKg >= 25 ? 0 : 1)
                    font.pixelSize: Math.max(10, root.diameter * 0.06)
                    font.bold: root.boldValues
                }

                Text {
                    id: motoKgTxt2
                    font.family: root.ff
                    text: 'kg'
                    opacity: 0.8
                    font.pixelSize: Math.max(10, root.diameter * 0.06)
                    font.bold: root.boldValues
                }
            }

            /**
              Value of power
              */
            Grid {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: root.gaugeHeight * 2.2
                spacing: 5

                Text {
                    id: powerTxt1
                    text: root.prettyNumber(Math.abs(root.power) >= 1000 ? root.power / 1000 : root.power, Math.abs(root.power) > 10000 ? 0 : 2)
                    font.family: root.ff
                    font.pixelSize: Math.max(10, root.diameter * 0.06)
                    font.bold: root.boldValues
                }

                Text {
                    id: powerTxt2
                    text: Math.abs(root.power) >= 1000 ? 'kw' : 'w'
                    font.family: root.ff
                    opacity: 0.8
                    font.pixelSize: Math.max(10, root.diameter * 0.06)
                    font.bold: root.boldValues
                }
            }


            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.gaugeHeight * 4
                anchors.left: parent.left
                anchors.leftMargin: root.gaugeHeight * 3.3

                Row {
                    anchors.left: parent.left
                    width: tempMotorTextBlock.width + tfetsIcoBlock.width
                    height: tfetsIcoBlock.height
                    spacing: 3

                    Item {
                        id: tfetsIcoBlock
                        anchors.verticalCenter: parent.verticalCenter
                        width: tfetsIco.width + 3
                        height: tfetsIco.height

                        Image {
                            id: tfetsIco
                            smooth: true
                            source: "qrc:/res/icons/motor.svg"
                            sourceSize.width: root.diameter * 0.05
                            sourceSize.height: root.diameter * 0.05
                            visible: false

                        }
                        ColorOverlay {
                            anchors.fill: tfetsIco
                            source: tfetsIco
                            color: Material.color(Material.Blue)
                        }
                    }

                    Item {
                        id: tempMotorTextBlock
                        width: tempMotorText.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: tempMotorText
                            font.family: root.ff
                            text: prettyNumber(root.tempMotor) + 'C'
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            color: root.tempMotor > 80 ? root.dangerTextColor : root.textColor;
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.gaugeHeight * 4
                anchors.right: parent.right
                anchors.rightMargin: root.gaugeHeight * 3.3

                Row {
                    anchors.right: parent.right
                    width: tmotIcoBlock.width + tfetsTextBlock.block
                    height: tmotIcoBlock.height
                    spacing: 3


                    Item {
                        id: tmotIcoBlock
                        anchors.verticalCenter: parent.verticalCenter
                        width: tmotIco.width + 3
                        height: tmotIco.height

                        Image {
                            id: tmotIco
                            smooth: true
                            source: "qrc:/res/icons/mcu.svg"
                            sourceSize.width: root.diameter * 0.05
                            sourceSize.height: root.diameter * 0.05
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: tmotIco
                            source: tmotIco
                            color: Material.color(Material.Blue)
                        }
                    }

                    Item {
                        id: tfetsTextBlock
                        width: tfetsText.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: tfetsText
                            font.family: root.ff
                            text: prettyNumber(root.tempFets, 1) + 'C'
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            color: root.tempFets > 80 ? root.dangerTextColor : root.textColor;
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.gaugeHeight * 2.7

                visible: root.tempBat > -200

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tbatIcoBlock.width + tbatTextBlock.block
                    height: tbatIcoBlock.height
                    spacing: 3

                    Item {
                        id: tbatIcoBlock
                        anchors.verticalCenter: parent.verticalCenter
                        width: tbatIco.width + 3
                        height: tbatIco.height

                        Image {
                            id: tbatIco
                            smooth: true
                            source: "qrc:/res/icons/battery.svg"
                            sourceSize.width: root.diameter * 0.05
                            sourceSize.height: root.diameter * 0.05
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: tbatIco
                            source: tbatIco
                            color: Material.color(Material.Blue)
                        }
                    }

                    Item {
                        id: tbatTextBlock
                        width: tbatText.width
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: tbatText
                            font.family: root.ff
                            text: root.prettyNumber(root.tempBat, 1) + 'C'
                            font.pixelSize: Math.max(10, root.diameter * 0.04)
                            color: root.tempBat > 80 ? root.dangerTextColor : root.textColor;
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    SkypuffBattery {
        id: batteryBlock
        gauge: root

        isCharging: root.power < 0
        isDischarging: root.power > 0
    }

}
