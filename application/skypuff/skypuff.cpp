#include "skypuff.h"

Skypuff::Skypuff(VescInterface *parent) : QObject(parent),
    vesc(parent), aliveTimerId(0), commandTimeoutTimerId(0)
{
    connect(vesc, SIGNAL(portConnectedChanged()), this, SLOT(portConnectedChanged()));
    connect(vesc->commands(), SIGNAL(printReceived(QString)), this, SLOT(printReceived(QString)));
    connect(vesc->commands(), SIGNAL(customAppDataReceived(QByteArray)), this, SLOT(customAppDataReceived(QByteArray)));
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

        emit newState("DISCONNECTED");
    }
    else
        this->sendCmdOrDisconnect("custom_app_data");
}

void Skypuff::timerEvent(QTimerEvent *event)
{
    if(event->timerId() == this->commandTimeoutTimerId) {
        this->killTimer(this->commandTimeoutTimerId);
        this->commandTimeoutTimerId = 0;
        vesc->emitMessageDialog(tr("Command timeout"),
                                tr("Skypuff command '<i>%1</i>' did not answered within %2ms timeout.<br/><br/>"
                                   "Make sure Skypuff custom app started on the ESC. And connection is stable.").arg(this->lastCmd).arg(commandTimeout),
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
    // Still waiting answer from previous command?
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
    if(!stopTimout("custom_app_data"))
        return;

    qWarning() << "customAppData" << data.length() << "bytes received";

    VByteArray vb(data);

    uint8_t version = vb.vbPopFrontUint8();

    if(version != skypuff_config_version) {
        vesc->emitMessageDialog(tr("Wrong config version"),
                                tr("Received skypuff version %1, my version %2.").arg(version).arg(skypuff_config_version),
                                true);
        vesc->disconnectPort();
        return;
    }

    this->state = (skypuff_state)vb.vbPopFrontUint8();
    this->cur_pos = vb.vbPopFrontInt32();

    this->drive_cfg.motor_poles = vb.vbPopFrontUint8();
    this->drive_cfg.gear_ratio = vb.vbPopFrontDouble32Auto();
    this->drive_cfg.wheel_diameter = vb.vbPopFrontDouble32Auto();

    qWarning() << state_str(this->state) << "mp" << this->drive_cfg.motor_poles << "gr" << this->drive_cfg.gear_ratio << "wd" << this->drive_cfg.wheel_diameter;

    this->skypuff_cfg.kg_to_amps = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.amps_per_sec = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.rope_length = vb.vbPopFrontInt32();
    this->skypuff_cfg.braking_length = vb.vbPopFrontInt32();
    this->skypuff_cfg.passive_braking_length = vb.vbPopFrontInt32();
    this->skypuff_cfg.slowing_length = vb.vbPopFrontInt32();
    this->skypuff_cfg.slow_erpm = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.rewinding_trigger_length = vb.vbPopFrontInt32();
    this->skypuff_cfg.unwinding_trigger_length = vb.vbPopFrontInt32();
    this->skypuff_cfg.pull_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.pre_pull_k = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.takeoff_pull_k = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.fast_pull_k = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.takeoff_trigger_length = vb.vbPopFrontInt32();
    this->skypuff_cfg.pre_pull_timeout = vb.vbPopFrontInt32();
    this->skypuff_cfg.takeoff_period = vb.vbPopFrontInt32();
    this->skypuff_cfg.brake_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.slowing_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.manual_brake_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.unwinding_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.rewinding_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.slow_max_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.manual_slow_max_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.manual_slow_speed_up_current = vb.vbPopFrontDouble32Auto();
    this->skypuff_cfg.manual_slow_erpm = vb.vbPopFrontDouble32Auto();

    qWarning() << "vb.length" << vb.length();
}
