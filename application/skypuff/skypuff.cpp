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

Skypuff::Skypuff(VescInterface *parent) : QObject(parent),
    vesc(parent), aliveTimerId(0), commandTimeoutTimerId(0), m_state("DISCONNECTED")
{
    connect(vesc, SIGNAL(portConnectedChanged()), this, SLOT(portConnectedChanged()));
    connect(vesc->commands(), SIGNAL(printReceived(QString)), this, SLOT(printReceived(QString)));
    connect(vesc->commands(), SIGNAL(customAppDataReceived(QByteArray)), this, SLOT(customAppDataReceived(QByteArray)));
}

void Skypuff::setState(const QString& newState)
{
    if(this->m_state != newState) {
        this->m_state = newState;
        emit this->stateChanged(this->m_state);
    }
}

void Skypuff::portConnectedChanged()
{
    if(!vesc->isPortConnected()) {
        // Stop timers
        if(this->aliveTimerId) {
            this->killTimer(this->aliveTimerId);
            this->aliveTimerId = 0;
        }
        if(this->commandTimeoutTimerId) {
            this->killTimer(this->commandTimeoutTimerId);
            this->commandTimeoutTimerId = 0;
        }

        setState("DISCONNECTED");
    }
    else
        this->sendCmdOrDisconnect("get_conf");
}

void Skypuff::timerEvent(QTimerEvent *event)
{
    if(event->timerId() == this->commandTimeoutTimerId) {
        this->killTimer(this->commandTimeoutTimerId);
        this->commandTimeoutTimerId = 0;
        vesc->emitMessageDialog(tr("Command timeout"),
                                tr("Skypuff command '<i>%1</i>' did not answered within %2ms timeout.<br/><br/>"
                                   "Make sure connection is stable. VESC running Skypuff enabled firmware. "
                                   "Motor configured, Custom User App started. Check it with 'skypuff' command.").arg(this->lastCmd).arg(commandTimeout),
                                true);
        vesc->disconnectPort();
    }
    else if(event->timerId() == this->aliveTimerId) {
        qWarning() << "Skypuff::timerEvent(): alive timer";
    }
    else
        qFatal("Skypuff::timerEvent(): unknown timer id %d", event->timerId());
}

bool Skypuff::sendCmd(const QString &cmd)
{
    if(!this->vesc->isPortConnected()) {
        vesc->emitMessageDialog(tr("Can't send command"),
                                tr("sendCmd(<i>%1</i>) while communication port is disconnected").arg(cmd),
                                true);
        return false;
    }

    if(this->commandTimeoutTimerId) {
        vesc->emitMessageDialog(tr("Can't send command"),
                                tr("sendCmd(<i>%1</i>) while still processing command '%2'..").arg(cmd).arg(this->lastCmd),
                                true);
        return false;
    }

    this->lastCmd = cmd;
    vesc->commands()->sendTerminalCmd(cmd);
    this->commandTimeoutTimerId = this->startTimer(this->commandTimeout, Qt::PreciseTimer);

    return true;
}

void Skypuff::sendCmdOrDisconnect(const QString &cmd)
{
    if(!this->sendCmd(cmd)) {
        vesc->disconnectPort();
    }
}

// Check the last command is the same or disconnect
bool Skypuff::stopTimout(const QString& cmd)
{
    if(this->lastCmd != cmd) {
        vesc->emitMessageDialog(tr("Incorrect last command"),
                                tr("stopTimeout(<i>%1</i>) while processing command '%2'..").arg(cmd).arg(this->lastCmd),
                                true);
        return false;
    }

    if(!this->commandTimeoutTimerId) {
        vesc->emitMessageDialog(tr("Incorrect timeout"),
                                tr("stopTimeout(<i>%1</i>) commandTimeoutTimerId is not set..").arg(cmd),
                                true);
        return false;

    }

    this->killTimer(this->commandTimeoutTimerId);
    this->commandTimeoutTimerId = 0;

    return true;
}

void Skypuff::printReceived(QString str)
{
    qWarning() << "printReceived" << str;
}

void Skypuff::customAppDataReceived(QByteArray data)
{
    if(!stopTimout("get_conf"))
        return;

    VByteArray vb(data);

    if(vb.length() < 1) {
        vesc->emitMessageDialog(tr("Can't deserialize"),
                                tr("Not enough data to deserialize version"),
                                true);
        vesc->disconnectPort();
        return;
    }

    uint8_t version = vb.vbPopFrontUint8();

    switch(version) {
    case 1:
        this->deserializeV1(vb);
        break;
    default:
        vesc->emitMessageDialog(tr("Wrong config version"),
                                tr("Received skypuff version %1, my version %2.").arg(version).arg(skypuff_config_version),
                                true);
        vesc->disconnectPort();
        return;
    }
    return;
}

void Skypuff::deserializeV1(VByteArray & vb)
{
    const int v1_settings_length = 114;
    if(vb.length() < v1_settings_length) {
        vesc->emitMessageDialog(tr("Can't deserialize"),
                                tr("%1 bytes is not enough to deserialize V1 %2 bytes settings")
                                .arg(vb.length())
                                .arg(v1_settings_length),
                                true);
        vesc->disconnectPort();
        return;
    }

    skypuff_state mcu_state;
    int cur_pos;
    QMLable_skypuff_config cfg;

    mcu_state = (skypuff_state)vb.vbPopFrontUint8();
    cur_pos = vb.vbPopFrontInt32();

    cfg.motor_poles = vb.vbPopFrontUint8();
    cfg.gear_ratio = vb.vbPopFrontDouble32Auto();
    cfg.wheel_diameter = vb.vbPopFrontDouble32Auto();

    cfg.amps_per_kg = vb.vbPopFrontDouble32Auto();
    cfg.amps_per_sec = vb.vbPopFrontDouble32Auto();
    cfg.rope_length = vb.vbPopFrontInt32();
    cfg.braking_length = vb.vbPopFrontInt32();
    cfg.passive_braking_length = vb.vbPopFrontInt32();

    cfg.slowing_length = vb.vbPopFrontInt32();
    cfg.slow_erpm = vb.vbPopFrontDouble32Auto();
    cfg.rewinding_trigger_length = vb.vbPopFrontInt32();
    cfg.unwinding_trigger_length = vb.vbPopFrontInt32();
    cfg.pull_current = vb.vbPopFrontDouble32Auto();

    cfg.pre_pull_k = vb.vbPopFrontDouble32Auto();
    cfg.takeoff_pull_k = vb.vbPopFrontDouble32Auto();
    cfg.fast_pull_k = vb.vbPopFrontDouble32Auto();
    cfg.takeoff_trigger_length = vb.vbPopFrontInt32();
    cfg.pre_pull_timeout = vb.vbPopFrontInt32();

    cfg.takeoff_period = vb.vbPopFrontInt32();
    cfg.brake_current = vb.vbPopFrontDouble32Auto();
    cfg.slowing_current = vb.vbPopFrontDouble32Auto();
    cfg.manual_brake_current = vb.vbPopFrontDouble32Auto();
    cfg.unwinding_current = vb.vbPopFrontDouble32Auto();

    cfg.rewinding_current = vb.vbPopFrontDouble32Auto();
    cfg.slow_max_current = vb.vbPopFrontDouble32Auto();
    cfg.manual_slow_max_current = vb.vbPopFrontDouble32Auto();
    cfg.manual_slow_speed_up_current = vb.vbPopFrontDouble32Auto();
    cfg.manual_slow_erpm = vb.vbPopFrontDouble32Auto();

    emit settingsChanged(cfg);

    (void)cur_pos;
    //emit newStats()

    setState(state_str(mcu_state));
}

QByteArray Skypuff::serializeV1(const QMLable_skypuff_config &cfg)
{
    VByteArray vb;

    vb.vbAppendUint8(1); // 1 byte version

    vb.vbAppendUint8(cfg.motor_poles);
    vb.vbAppendDouble32Auto(cfg.gear_ratio);
    vb.vbAppendDouble32Auto(cfg.wheel_diameter);

    vb.vbAppendDouble32Auto(cfg.amps_per_kg);
    vb.vbAppendDouble32Auto(cfg.amps_per_sec);
    vb.vbAppendInt32(cfg.rope_length);
    vb.vbAppendInt32(cfg.braking_length);
    vb.vbAppendInt32(cfg.passive_braking_length);
    vb.vbAppendInt32(cfg.slowing_length);
    vb.vbAppendDouble32Auto(cfg.slow_erpm);
    vb.vbAppendInt32(cfg.rewinding_trigger_length);
    vb.vbAppendInt32(cfg.unwinding_trigger_length);
    vb.vbAppendDouble32Auto(cfg.pull_current);
    vb.vbAppendDouble32Auto(cfg.pre_pull_k);
    vb.vbAppendDouble32Auto(cfg.takeoff_pull_k);
    vb.vbAppendDouble32Auto(cfg.fast_pull_k);
    vb.vbAppendInt32(cfg.takeoff_trigger_length);
    vb.vbAppendInt32(cfg.pre_pull_timeout);
    vb.vbAppendInt32(cfg.takeoff_period);
    vb.vbAppendDouble32Auto(cfg.brake_current);
    vb.vbAppendDouble32Auto(cfg.slowing_current);
    vb.vbAppendDouble32Auto(cfg.manual_brake_current);
    vb.vbAppendDouble32Auto(cfg.unwinding_current);
    vb.vbAppendDouble32Auto(cfg.rewinding_current);
    vb.vbAppendDouble32Auto(cfg.slow_max_current);
    vb.vbAppendDouble32Auto(cfg.manual_slow_max_current);
    vb.vbAppendDouble32Auto(cfg.manual_slow_speed_up_current);
    vb.vbAppendDouble32Auto(cfg.manual_slow_erpm);

    return vb;
}

void Skypuff::saveSettings(const QMLable_skypuff_config& cfg)
{
    qWarning() << "amps_per_kg" << cfg.amps_per_sec;

    vesc->commands()->sendCustomAppData(serializeV1(cfg));
}
