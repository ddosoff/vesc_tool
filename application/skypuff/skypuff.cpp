/*
    Copyright 2020 Kirill Kostiuchenko	kisel2626@gmail.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#include "skypuff.h"

Skypuff::Skypuff(VescInterface *v) : QObject(),
    vesc(v),
    aliveTimerId(0), aliveTimeoutTimerId(0), getConfTimeoutTimerId(0),
    curTac(0), erpm(0), amps(0), power(0),
    tempFets(0), tempMotor(0),
    whIn(0), whOut(0),
    // Compile regexps once here
    reBraking("(\\d.\\.?\\d*)Kg \\((-?\\d+.?\\d*)A"),
    rePull("(\\d.\\.?\\d*)Kg \\((-?\\d+.?\\d*)A"), // absolute kg, signed amps
    rePos("(\\d.\\.?\\d*)m \\((-?\\d+) steps"), // absolute meters and signed steps
    reSpeed("-?(\\d.\\.?\\d*)ms \\((-?\\d+) ERPM"), // absolute ms and signed erpm
    rePullingHigh("pulling too high .?(\\d+.\\d+)Kg"),
    reUnwindedFromSlowing("Unwinded from slowing zone .?(\\d+.\\d+)m"),
    rePrePullTimeout("Pre pull (\\d+.\\d+)s timeout passed"),
    reMotionDetected("Motion (\\d+.\\d+)m"),
    reTakeoffTimeout("Takeoff (\\d+.\\d+)s")
{
    // Fill message types
    messageTypes[PARAM_TEXT] = "--";
    messageTypes[PARAM_POS] = "pos";
    messageTypes[PARAM_SPEED] = "speed";
    messageTypes[PARAM_BRAKING] = "braking";
    messageTypes[PARAM_PULL] = "pull";
    messageTypes[PARAM_TEMP_FETS] = "t_fets";
    messageTypes[PARAM_TEMP_MOTOR] = "t_motor";
    messageTypes[PARAM_WH_IN] = "wh_in";
    messageTypes[PARAM_WH_OUT] = "wh_out";

    connect(vesc, SIGNAL(portConnectedChanged()), this, SLOT(portConnectedChanged()));
    connect(vesc, SIGNAL(messageDialog(QString,QString,bool,bool)), this, SLOT(logVescDialog(const QString&,const QString&)));
    connect(vesc->commands(), SIGNAL(printReceived(QString)), this, SLOT(printReceived(QString)));
    connect(vesc->commands(), SIGNAL(customAppDataReceived(QByteArray)), this, SLOT(customAppDataReceived(QByteArray)));

    // Can't use Q_ENUM because skypuff_state declared out of Q_OBJECT class
    QString eof = "UNKNOWN";
    for(int i = 0;;i++) {
        QString s = state_str((skypuff_state)i);
        if(eof == s)
            break;
        h_states[s] = i;
    }

    setState("DISCONNECTED");
}

void Skypuff::logVescDialog(const QString & title, const QString & text)
{
    qWarning() << "-- VESC:" << title;
    qWarning() << "  --" << text;
}

void Skypuff::setState(const QString& newState)
{
    if(state != newState) {
        state = newState;
        emit stateChanged(state);

        // Translate to UI
        if(!newState.compare("DISCONNECTED"))
            stateText = tr("Disconnected");
        else if(!newState.compare("BRAKING"))
            stateText = tr("Braking");
        else if(!newState.compare("MANUAL_BRAKING"))
            stateText = tr("Manual Braking");
        else if(!newState.compare("MANUAL_SLOW_SPEED_UP"))
            stateText = tr("Manual Speed Up");
        else if(!newState.compare("MANUAL_SLOW"))
            stateText = tr("Manual Slow");
        else if(!newState.compare("MANUAL_SLOW_BACK_SPEED_UP"))
            stateText = tr("Manual Speed Up Back");
        else if(!newState.compare("MANUAL_SLOW_BACK"))
            stateText = tr("Manual Slow Back");
        else if(!newState.compare("BRAKING_EXTENSION"))
            stateText = tr("Braking Extension");
        else if(!newState.compare("UNWINDING"))
            stateText = tr("Unwinding");
        else if(!newState.compare("REWINDING"))
            stateText = tr("Rewinding");
        else if(!newState.compare("SLOWING"))
            stateText = tr("Slowing");
        else if(!newState.compare("SLOW"))
            stateText = tr("Slow");
        else if(!newState.compare("PRE_PULL"))
            stateText = tr("Pre Pull");
        else if(!newState.compare("TAKEOFF_PULL"))
            stateText = tr("Takeoff Pull");
        else if(!newState.compare("PULL"))
            stateText = tr("Pull");
        else if(!newState.compare("FAST_PULL"))
            stateText = tr("Fast Pull");
        else if(!newState.compare("UNITIALIZED"))
            stateText = tr("No Valid Settings");
        else
            stateText = newState;

        emit stateTextChanged(stateText);
    }
}

void Skypuff::portConnectedChanged()
{
    if(vesc->isPortConnected()) {
        this->sendGetConf();
    }
    else {
        // Stop timers
        if(aliveTimerId) {
            killTimer(aliveTimerId);
            aliveTimerId = 0;
        }
        if(getConfTimeoutTimerId) {
            killTimer(getConfTimeoutTimerId);
            getConfTimeoutTimerId = 0;
        }
        if(this->aliveTimeoutTimerId) {
            killTimer(aliveTimeoutTimerId);
            aliveTimeoutTimerId = 0;
        }

        setState("DISCONNECTED");
    }
}

void Skypuff::timerEvent(QTimerEvent *event)
{
    if(event->timerId() == getConfTimeoutTimerId) {
        killTimer(getConfTimeoutTimerId);
        getConfTimeoutTimerId = 0;
        vesc->emitMessageDialog(tr("Command 'get_conf' timeout"),
                                tr("Skypuff MCU did not answered within %2ms timeout.<br/><br/>"
                                   "Make sure connection is stable. VESC running Skypuff enabled firmware. "
                                   "Motor configured, Custom User App started. Check it with 'skypuff' command.").arg(commandTimeout),
                                true);
        vesc->disconnectPort();
    }
    else if(event->timerId() == aliveTimeoutTimerId) {
        killTimer(aliveTimeoutTimerId);
        aliveTimeoutTimerId = 0;
        vesc->emitMessageDialog(tr("Command 'alive' timeout"),
                                tr("Skypuff MCU did not answered within %2ms timeout.<br/><br/>"
                                   "Make sure connection is stable. VESC running Skypuff enabled firmware. "
                                   "Motor configured, Custom User App started. Check it with 'skypuff' command.").arg(commandTimeout),
                                true);
        vesc->disconnectPort();
    }
    else if(event->timerId() == this->aliveTimerId) {
        sendAlive();
    }
    else
        qFatal("Skypuff::timerEvent(): unknown timer id %d", event->timerId());
}

void Skypuff::sendGetConf()
{
    if(getConfTimeoutTimerId) {
        vesc->emitMessageDialog(tr("Can't send 'get_conf' command"),
                                tr("Timer already activated: '%2'..").arg(getConfTimeoutTimerId),
                                true);
        vesc->disconnectPort();
        return;
    }

    vesc->commands()->sendTerminalCmd("get_conf");
    getConfTimeoutTimerId = startTimer(commandTimeout, Qt::PreciseTimer);
}

void Skypuff::sendAlive()
{
    if(aliveTimeoutTimerId) {
        vesc->emitMessageDialog(tr("Can't send 'alive' command"),
                                tr("Timer already activated: '%2'..").arg(aliveTimeoutTimerId),
                                true);
        vesc->disconnectPort();
        return;
    }

    VByteArray vb;

    vb.vbAppendUint8(SK_COMM_ALIVE); // Version
    vb.vbAppendInt32(aliveTimeout);

    vesc->commands()->sendCustomAppData(vb);
    aliveResponseDelay.start();
    aliveTimeoutTimerId = startTimer(commandTimeout, Qt::PreciseTimer);
}

// Will not make it too complicate with timeout
void Skypuff::sendSettings(const QMLable_skypuff_config& cfg)
{
    vesc->commands()->sendCustomAppData(cfg.serializeV1());
}

// Parse known command and payload
bool Skypuff::parsePrintMessage(QStringRef &str, MessageTypeAndPayload &c)
{
    int len = str.length();

    if(!len)
        return false;

    int i;

    // Skip spaces or ','
    for(i = 0;(str[i].isSpace() || str[i] == ',') && i < len;i++);

    if(i == len)
        return false;

    if(i)
        str = str.mid(i);

    for(auto ci = messageTypes.constBegin();ci != messageTypes.constEnd();ci++)
        if(str.startsWith(ci.value())) {
            // Payload up to next '--' or end of string
            c.first = ci.key();

            int e = str.indexOf(c.first == PARAM_TEXT ? "--" : ",", ci.value().length());
            if(e == -1)
                e = str.length();

            c.second = str.mid(ci.value().length(), e - ci.value().length()).trimmed();
            str = str.mid(e);

            return true;
        }

    // Unknown command type, just ignore
    return false;
}

void Skypuff::printReceived(QString str)
{
    // Parse state
    int i = str.indexOf(':');

    if(i == -1) {
        qWarning() << "Can't parse state, no colon" << str;
        return;
    }

    QString p_state = str.left(i);

    if(!h_states.contains(p_state)) {
        qWarning() << "Can't parse state, unknown state" << str;
        return;
    }

    QStringRef rStr = str.midRef(i + 1); // Skip ':'
    QStringList messages;

    // Parse messages with types
    MessageTypeAndPayload c;
    while(parsePrintMessage(rStr, c)) {
        switch(c.first) {
        case PARAM_TEXT: // -- Hello baby
            messages.append(c.second.toString());
            break;
        case PARAM_SPEED: // "-0.0ms (-0 ERPM)"
            if(reSpeed.indexIn(c.second.toString()) != -1)
                setSpeed(reSpeed.cap(2).toFloat());
            break;
        case PARAM_POS: // "0.62m (151 steps)"
            if(rePos.indexIn(c.second.toString()) != -1)
                setPos(rePos.cap(2).toFloat());
            break;
        case PARAM_TEMP_FETS: // "29.1C"
            setTempFets(c.second.left(c.second.length() - 1).toFloat());
            break;
        case PARAM_TEMP_MOTOR: // "29.1C"
            setTempMotor(c.second.left(c.second.length() - 1).toFloat());
            break;
        case PARAM_WH_IN: // "0.003Wh"
            setWhIn(c.second.left(c.second.length() - 2).toFloat());
            break;
        case PARAM_WH_OUT: // "0.003Wh"
            setWhOut(c.second.left(c.second.length() - 2).toFloat());
            break;
        default:
            break;
        }
    };

    // Yeagh, we know the state!
    setState(p_state);

    // Emit messages signals
    if(!messages.isEmpty()) {
        QString title = messages.takeFirst();

        // Only title available?
        if(messages.isEmpty())
            setStatus(title);
        else {
            vesc->emitMessageDialog(title, messages.join("\n"), false);\
        }
    }
}

void Skypuff::customAppDataReceived(QByteArray data)
{
    VByteArray vb(data);

    if(vb.length() < 1) {
        vesc->emitMessageDialog(tr("Can't deserialize"),
                                tr("Not enough data to deserialize command byte"),
                                true);
        vesc->disconnectPort();
        return;
    }

    skypuff_custom_app_data_command command = (skypuff_custom_app_data_command)vb.vbPopFrontUint8();

    switch(command) {
    case SK_COMM_ALIVE:
        processAlive(vb);
        break;
    case SK_COMM_SETTINGS_V1:
        processSettingsV1(vb);
        break;
    default:
        vesc->emitMessageDialog(tr("Unknown CUSTOM_APP_DATA command"),
                                tr("Received commad: '%1'.").arg((int)command),
                                true);
        vesc->disconnectPort();
        return;
    }

}

void Skypuff::processAlive(VByteArray &vb)
{
    // alive could be set from UI, timer is not necessary but possible
    if(aliveTimeoutTimerId) {
        killTimer(aliveTimeoutTimerId);
        aliveTimeoutTimerId = 0;
    }
    else {
        qWarning() << "alive stats received, but timeout timer is not set";
    }

    // Enough data?
    const int alive_length = 1 + 4 * 4;
    if(vb.length() < alive_length) {
        vesc->emitMessageDialog(tr("Can't deserialize alive command"),
                                tr("Received %1 bytes, expected %2 bytes!").arg(vb.length()).arg(alive_length),
                                true);
        vesc->disconnectPort();
    }

    smooth_motor_mode newMotorMode = (smooth_motor_mode)vb.vbPopFrontUint8();
    int newTac = vb.vbPopFrontInt32();
    float newErpm = vb.vbPopFrontDouble32Auto();
    float newAmps = vb.vbPopFrontDouble32Auto();
    float newPower = vb.vbPopFrontDouble32Auto();

    if(vb.length()) {
        vesc->emitMessageDialog(tr("Extra bytes received with alive stats"),
                                tr("Received %1 extra bytes!").arg(vb.length()),
                                true);
        vesc->disconnectPort();
    }

    setPos(newTac);
    setSpeed(newErpm);
    setMotor(newMotorMode, newAmps, newPower);
}

void Skypuff::processSettingsV1(VByteArray &vb)
{
    // Configuration could be set from console
    // Timeout timer is not necessary, but possible
    if(getConfTimeoutTimerId) {
        killTimer(getConfTimeoutTimerId);
        getConfTimeoutTimerId = 0;
    }
    else {
        qWarning() << "settings received, but get_conf timeout timer is not set";
    }

    // Enough data?
    const int v1_settings_length = 123;
    if(vb.length() < v1_settings_length) {
        vesc->emitMessageDialog(tr("Can't deserialize V1 settings"),
                                tr("Received %1 bytes, expected %2 bytes!").arg(vb.length()).arg(v1_settings_length),
                                true);
        vesc->disconnectPort();
    }

    // Get state and pos
    skypuff_state mcu_state;

    mcu_state = (skypuff_state)vb.vbPopFrontUint8();
    setState(state_str(mcu_state));

    cfg.v_in = vb.vbPopFrontDouble32Auto();
    tempFets = vb.vbPopFrontDouble16(1e1);
    tempMotor = vb.vbPopFrontDouble16(1e1);
    whIn = vb.vbPopFrontDouble32(1e4);
    whOut = vb.vbPopFrontDouble32(1e4);

    emit tempFetsChanged(tempFets);
    emit tempMotorChanged(tempMotor);
    emit whInChanged(whIn);
    emit whOutChanged(whOut);

    cfg.deserializeV1(vb);
    // Update maximum motor current to calculate scales
    cfg.motor_max_current = vesc->mcConfig()->getParamDouble("l_current_max");

    emit settingsChanged(cfg);

    processAlive(vb);

    if(vb.length()) {
        vesc->emitMessageDialog(tr("Extra bytes received with V1 settings"),
                                tr("Received %1 extra bytes!").arg(vb.length()),
                                true);
        vesc->disconnectPort();
    }

    // Override position
    emit posChanged(cfg.tac_steps_to_meters(curTac));
    emit brakingRangeChanged(isBrakingRange());
    emit brakingExtensionRangeChanged(isBrakingExtensionRange());

    // Start alives sequence after first get_conf
    if(!aliveTimerId)
        aliveTimerId = startTimer(aliveTimerDelay, Qt::PreciseTimer);
}

// overrideChanged after new seetings to update ranges flags
void Skypuff::setPos(const int new_pos)
{
    if(new_pos != curTac) {
        bool wasBrakingRange = isBrakingRange();
        bool wasBrakingExtensionRange = isBrakingExtensionRange();

        curTac = new_pos;
        emit posChanged(cfg.tac_steps_to_meters(new_pos));

        bool newBrakingRange = isBrakingRange();
        bool newBrakingExtensionRange = isBrakingExtensionRange();

        if(wasBrakingRange != newBrakingRange)
            emit brakingRangeChanged(newBrakingRange);

        if(wasBrakingExtensionRange != newBrakingExtensionRange)
            emit brakingExtensionRangeChanged(newBrakingExtensionRange);
    }
}

void Skypuff::setSpeed(float new_erpm)
{
    if(erpm != new_erpm) {
        erpm = new_erpm;
        emit speedChanged(cfg.erpm_to_ms(new_erpm));
    }
}

void Skypuff::setMotor(const smooth_motor_mode newMode, const float newAmps, const float newPower)
{
    if(smoothMotorMode != newMode) {
        smoothMotorMode = newMode;

        motorModeText = motor_mode_str(newMode);

        switch(smoothMotorMode) {
        case MOTOR_RELEASED:
            motorModeText = tr("Released");
            break;
        case MOTOR_CURRENT:
            motorModeText = tr("Pull");
            break;
        case MOTOR_BRAKING:
            motorModeText = tr("Brake");
            break;
        case MOTOR_SPEED:
            motorModeText = tr("Speed");
            break;
        }
        emit motorModeChanged(motorModeText);
    }


    if(amps != newAmps) {
        amps = newAmps;

        emit motorKgChanged(amps / cfg.amps_per_kg);
    }

    if(power != newPower) {
        power = newPower;

        emit powerChanged(newPower);
    }
}

void Skypuff::setTempFets(const float newTempFets)
{
    if(tempFets != newTempFets) {
        tempFets = newTempFets;
        emit tempFetsChanged(newTempFets);
    }
}

void Skypuff::setTempMotor(const float newTempMotor)
{
    if(tempMotor != newTempMotor) {
        tempMotor = newTempMotor;
        emit tempMotorChanged(newTempMotor);
    }
}

void Skypuff::setWhIn(const float newWhIn)
{
    if(whIn != newWhIn) {
        whIn = newWhIn;
        emit whInChanged(newWhIn);
    }
}

void Skypuff::setWhOut(const float newWhOut)
{
    if(whOut != newWhOut) {
        whOut = newWhOut;
        emit whOutChanged(newWhOut);
    }
}

// Translate status messages to UI language
void Skypuff::setStatus(const QString& mcuStatus)
{
    QString s = mcuStatus;

    // -- slow pulling too high -1.0Kg (-7.1A) is more 1.0Kg (7.0A)
    if(rePullingHigh.indexIn(s) != -1)
        s = tr("Stopped by pulling %1Kg").arg(rePullingHigh.cap(1));

    // -- Unwinded from slowing zone 4.00m (972 steps)
    else if(reUnwindedFromSlowing.indexIn(s) != -1)
        s = tr("%1m slowing zone unwinded").arg(reUnwindedFromSlowing.cap(1));

    // -- Pre pull 2.0s timeout passed, saving position
    else if(rePrePullTimeout.indexIn(s) != -1)
        s = tr("%1s passed, detecting motion").arg(rePrePullTimeout.cap(1));

    // -- Motion 0.10m (24 steps) detected
    else if(reMotionDetected.indexIn(s) != -1)
        s = tr("%1m motion detected").arg(reMotionDetected.cap(1));

    // -- Takeoff 5.0s timeout passed
    else if(reTakeoffTimeout.indexIn(s) != -1)
        s = tr("%1s takeoff, normal pull").arg(reTakeoffTimeout.cap(1));

    emit statusChanged(s);
}
