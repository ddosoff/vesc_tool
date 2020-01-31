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
#include <QSound>
#include "skypuff.h"

Skypuff::Skypuff(VescInterface *v) : QObject(),
    vesc(v),
    aliveTimerId(0),
    aliveTimeoutTimerId(0),
    getConfTimeoutTimerId(0),
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
    player = new QMediaPlayer(this);
    playlist = new QMediaPlaylist(player);
    player->setPlaylist(playlist);

    // Fill message types
    messageTypes[PARAM_TEXT] = "--";
    messageTypes[PARAM_POS] = "pos";
    messageTypes[PARAM_SPEED] = "speed";
    messageTypes[PARAM_BRAKING] = "braking";
    messageTypes[PARAM_PULL] = "pull";
    messageTypes[PARAM_TEMP_FETS] = "t_fets";
    messageTypes[PARAM_TEMP_MOTOR] = "t_motor";
    messageTypes[PARAM_TEMP_BAT] = "t_bat";
    messageTypes[PARAM_WH_IN] = "wh_in";
    messageTypes[PARAM_WH_OUT] = "wh_out";
    messageTypes[PARAM_FAULT] = "fault";
    messageTypes[PARAM_V_BAT] = "v_bat";

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
        h_states[s] = (skypuff_state)i;
    }

    // Fill faults string codes
    eof = "Unknown fault";
    for(int i = 0;;i++) {
        QString s = Commands::faultToStr((mc_fault_code)i);
        if(eof == s)
            break;
        h_faults[s] = (mc_fault_code)i;
    }

    setState("DISCONNECTED");
    clearStats();
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

        // No more fault :)
        setState("DISCONNECTED");

        // Reset scales
        cfg.clearScales();
        clearStats();
        scalesUpdated();
    }
}

void Skypuff::clearStats()
{
    vBat = 0;
    curTac = 0;
    erpm = 0;
    amps = 0;
    power = 0;
    tempFets = 0;
    tempMotor = 0;
    tempBat = 0;
    whIn = 0;
    whOut = 0;

    setFault(FAULT_CODE_NONE);
    playingFault = FAULT_CODE_NONE;
}

void Skypuff::timerEvent(QTimerEvent *event)
{
    if(event->timerId() == getConfTimeoutTimerId) {
        killTimer(getConfTimeoutTimerId);
        getConfTimeoutTimerId = 0;
        vesc->emitMessageDialog(tr("Command 'get_conf' timeout"),
                                tr("Skypuff MCU did not answered within %2ms timeout.<br/><br/>"
                                   "Make sure connection is stable. VESC running Skypuff enabled firmware. "
                                   "Motor configured, Custom User App started.<br/><br/>Use vesc_tool terminal 'skypuff' command.").arg(commandTimeout),
                                true);
        vesc->disconnectPort();
        player->setMedia(QUrl("qrc:/res/sounds/alert.mp3"));
        player->play();
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

QMLable_skypuff_config Skypuff::loadSettings(const QString & fileName)
{
    QMLable_skypuff_config c;
    QSettings f(QUrl(fileName).toLocalFile(), QSettings::IniFormat);
    c.loadV1(f);

    return c;
}

bool Skypuff::saveSettings(const QString & fileName, const QMLable_skypuff_config& c)
{
    QSettings f(QUrl(fileName).toLocalFile(), QSettings::IniFormat);
    if(f.status() != QSettings::NoError)
        return false;

    return c.saveV1(f);
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
    auto fault_parsed = h_faults.end();

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
        case PARAM_TEMP_BAT: // "29.1C"
            setTempBat(c.second.left(c.second.length() - 1).toFloat());
            break;
        case PARAM_WH_IN: // "0.003Wh"
            setWhIn(c.second.left(c.second.length() - 2).toFloat());
            break;
        case PARAM_WH_OUT: // "0.003Wh"
            setWhOut(c.second.left(c.second.length() - 2).toFloat());
            break;
        case PARAM_V_BAT: // "23.3V"
            setVBat(c.second.left(c.second.length() - 1).toFloat());
            break;
        case PARAM_FAULT: // FAULT_CODE_OVER_VOLTAGE
            fault_parsed = h_faults.find(c.second.toString());
            if(fault_parsed == h_faults.end()) {
                qWarning() << "Unknown fault string" << c.second;
                vesc->emitMessageDialog(tr("Can't parse fault"),
                                        tr("Unknown code: %s").arg(c.second),
                                        false, false);
            }
            break;
        default:
            break;
        }
    };

    // Yeagh, we know the state!
    setState(p_state);

    // Fault parsed?
    if(fault_parsed != h_faults.end())
        setFault(fault_parsed.value());

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
    float newErpm = vb.vbPopFrontDouble32(1e1);
    float newAmps = vb.vbPopFrontDouble32(1e1);
    float newPower = vb.vbPopFrontDouble32(1e1);

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
    const int v1_settings_length = 160;
    if(vb.length() < v1_settings_length) {
        vesc->emitMessageDialog(tr("Can't deserialize V1 settings"),
                                tr("Received %1 bytes, expected %2 bytes!").arg(vb.length()).arg(v1_settings_length),
                                true);
        vesc->disconnectPort();
    }

    // Get state and pos
    skypuff_state mcu_state;

    mcu_state = (skypuff_state)vb.vbPopFrontUint8();
    fault = (mc_fault_code)vb.vbPopFrontUint8();

    cfg.motor_max_current = vb.vbPopFrontDouble16(1e1);
    cfg.fet_temp_max = vb.vbPopFrontDouble16(1e1);
    cfg.motor_temp_max = vb.vbPopFrontDouble16(1e1);
    cfg.v_in_min = vb.vbPopFrontDouble32(1e2);
    cfg.v_in_max = vb.vbPopFrontDouble32(1e2);

    cfg.battery_cells = (int)vb.vbPopFrontUint8();
    cfg.battery_type = (int)vb.vbPopFrontUint8();

    vBat = vb.vbPopFrontDouble32(1e2);
    tempFets = vb.vbPopFrontDouble16(1e1);
    tempMotor = vb.vbPopFrontDouble16(1e1);
    tempBat = vb.vbPopFrontDouble16(1e1);
    whIn = vb.vbPopFrontDouble32(1e4);
    whOut = vb.vbPopFrontDouble32(1e4);

    cfg.deserializeV1(vb);

    setState(state_str(mcu_state));

    emit settingsChanged(cfg);

    processAlive(vb);

    if(vb.length()) {
        vesc->emitMessageDialog(tr("Extra bytes received with V1 settings"),
                                tr("Received %1 extra bytes!").arg(vb.length()),
                                true);
        vesc->disconnectPort();
    }

    scalesUpdated();

    // Start alives sequence after first get_conf
    if(!aliveTimerId)
        aliveTimerId = startTimer(aliveTimerDelay, Qt::PreciseTimer);
}

void Skypuff::scalesUpdated()
{
    // Some new warnings or faults?
    playAudio();

    emit faultChanged(getFaultTranslation());
    emit tempFetsChanged(tempFets);
    emit tempMotorChanged(tempMotor);
    emit tempBatChanged(tempBat);
    emit whInChanged(whIn);
    emit whOutChanged(whOut);

    // Battery
    emit batteryChanged(getBatteryPercents());
    emit batteryScalesChanged(isBatteryScaleValid());
    emit batteryWarningChanged(isBatteryWarning());
    emit batteryBlinkingChanged(isBatteryBlinking());

    // Position
    emit posChanged(cfg.tac_steps_to_meters(curTac));
    emit brakingRangeChanged(isBrakingRange());
    emit brakingExtensionRangeChanged(isBrakingExtensionRange());
}

// Priority to faults, play warnings only once if no fault
void Skypuff::playAudio()
{
    if(fault == FAULT_CODE_NONE) {
        // In case of fault gone play prev fault once
        playlist->setPlaybackMode(QMediaPlaylist::Sequential);

        // Still playing old fault?
        if(player->state() == QMediaPlayer::PlayingState)
            return;

        // Play some warnings?
        playlist->clear();

        if(isBatteryTooHigh()) {
            playlist->addMedia(QUrl(tr("qrc:/res/sounds/Battery charged too high.mp3")));
            emit statusChanged(tr("Battery charged too high"), true);
        }

        if(isBatteryTooLow()) {
            playlist->addMedia(QUrl(tr("qrc:/res/sounds/Battery charged too low.mp3")));
            emit statusChanged(tr("Battery charged too low"), true);
        }

        if(!playlist->isEmpty())
            player->play();

        return;
    }

    playlist->setPlaybackMode(QMediaPlaylist::Loop);

    // Still playing the same fault?
    if(playingFault == fault && player->state() == QMediaPlayer::PlayingState) {
        // Do not interrupt playing
        return;
    }

    playingFault = fault;

    playlist->clear();
    playlist->addMedia(QUrl("qrc:/res/sounds/Alert.mp3"));

    // Known specific alerts?
    switch (fault) {
    case FAULT_CODE_OVER_VOLTAGE:
        playlist->addMedia(QUrl(tr("qrc:/res/sounds/Overvoltage.mp3")));
        break;
    default:
        playlist->addMedia(QUrl(tr("qrc:/res/sounds/Fault code.mp3")));
        break;
    }

    player->play();
}

QString Skypuff::getFaultTranslation()
{
    switch (fault) {
    case FAULT_CODE_NONE:
        return QString();
    case FAULT_CODE_OVER_VOLTAGE:
        return tr("Battery overvoltage %1V").arg(vBat);
    default:
        return Commands::faultToStr(fault);
    }
}

void Skypuff::setFault(const mc_fault_code newFault)
{
    if(fault != newFault) {
        fault = newFault;
        playAudio();
        emit faultChanged(getFaultTranslation());
    }
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

void Skypuff::setTempBat(const float newTempBat)
{
    if(tempBat != newTempBat) {
        tempBat = newTempBat;
        emit tempBatChanged(newTempBat);
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

float Skypuff::getBatteryPercents()
{
    // Please implement lipo discharge polynom approximated curve here
    // But for now just linear function
    return (vBat - cfg.v_in_min) / (cfg.v_in_max - cfg.v_in_min) * (float)100;
}

bool Skypuff::isBatteryTooHigh()
{
    if(!isBatteryScaleValid())
        return false;

    return getBatteryPercents() > (float)95;
}

bool Skypuff::isBatteryTooLow()
{
    if(!isBatteryScaleValid())
        return false;

    return getBatteryPercents() < (float)5;
}

bool Skypuff::isBatteryBlinking()
{
    if(!isBatteryScaleValid())
        return false;

    float p = getBatteryPercents();
    return  p  > (float)97 || p < (float)3;
}

void Skypuff::setVBat(const float newVBat)
{
    if(vBat != newVBat) {
        bool oldWarning = isBatteryWarning();
        bool oldBlinking = isBatteryBlinking();

        vBat = newVBat;
        emit batteryChanged(getBatteryPercents());

        bool newWarning = isBatteryWarning();
        bool newBlinking = isBatteryBlinking();

        if(oldWarning != newWarning) {
            emit batteryWarningChanged(newWarning);
        }

        if(newWarning)
            playAudio();

        if(oldBlinking != newBlinking)
            emit batteryBlinkingChanged(newBlinking);
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
