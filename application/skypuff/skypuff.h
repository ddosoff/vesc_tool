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
#ifndef SKYPUFF_H
#define SKYPUFF_H

#include <QElapsedTimer>
#include "vescinterface.h"
#include "qmlable_skypuff_types.h"

const int aliveTimerDelay = 333; // milliseconds
const int aliveTimeout = 500;
const int commandTimeout = 300;


/*
 * After vesc is connected, Skypuff will ask configuration and
 * will starts sending alive commands.
 *
 * Received MCU terminal prints will be parsed, CUSTOM_APP_DATA
 * deserialized and translated to QML accessible properties and signals.
 *
 * Sorry for some hardcore stings parsing.
 * It's not too much difference from binary in the end.
 *
 * If no answer within commandTimeout, vesc will be disconnected
 * and error message thrown via vesc interface.
 */
class Skypuff : public QObject
{
    Q_OBJECT

    // I tried to make enum skypuff_state QML accesible, but ..
    Q_PROPERTY(QString state READ getState NOTIFY stateChanged)
    // Translated state
    Q_PROPERTY(QString stateText READ getStateText NOTIFY stateTextChanged)

    // To enable transitions to braking, if pos below or equal braking_length + braking_extension_length
    Q_PROPERTY(bool isBrakingExtensionRange READ isBrakingExtensionRange NOTIFY brakingExtensionRangeChanged)
    // To enable manual_slow buttons
    Q_PROPERTY(bool isBrakingRange READ isBrakingRange NOTIFY brakingRangeChanged)
    Q_PROPERTY(float ropeMeters READ getRopeMeters NOTIFY settingsChanged)
    Q_PROPERTY(float drawnMeters READ getDrawnMeters NOTIFY posChanged)
    Q_PROPERTY(float leftMeters READ getLeftMeters NOTIFY posChanged)
    Q_PROPERTY(float speedMs READ getSpeedMs NOTIFY speedChanged)
    Q_PROPERTY(QString motorMode READ getMotorMode NOTIFY motorModeChanged)
    Q_PROPERTY(float motorKg READ getMotorKg NOTIFY motorKgChanged)
    Q_PROPERTY(float power READ getPower NOTIFY powerChanged)
public:
    Skypuff(VescInterface *parent = 0);

    Q_INVOKABLE void sendTerminal(const QString &c) {vesc->commands()->sendTerminalCmd(c);}

    // All this types conversion between C++ and QML is very strange...
    Q_INVOKABLE QMLable_skypuff_config emptySettings() {return QMLable_skypuff_config();}
    Q_INVOKABLE void sendSettings(const QMLable_skypuff_config& cfg);

signals:
    /* It is simple to work with QML text states:
     *
     * DISCONNECTED - VESC is disconnected or connected but state not detected yet
     * UNITIALIZED - Skypuff app is waiting for correct settings
     * BRAKING .. and all skypuff states
     */
    void stateChanged(const QString& newState); // Clear state
    void stateTextChanged(const QString& newStateText);
    void settingsChanged(const QMLable_skypuff_config & cfg);
    void statusChanged(const QString &status);
    void brakingExtensionRangeChanged(const bool isBrakingExtensionRange);
    void brakingRangeChanged(const bool isBrakingRange);
    void posChanged(const float meters);
    void speedChanged(const float ms);
    void motorModeChanged(const QString& newMotorMode);
    void motorKgChanged(const float kg);
    void powerChanged(const float power);
protected slots:
    void printReceived(QString str);
    void customAppDataReceived(QByteArray data);
    void portConnectedChanged();
    void logVescDialog(const QString & title, const QString & text);
protected:
    // Parsed messages from prints
    enum MessageType {
        PARAM_TEXT,
        PARAM_POS,
        PARAM_SPEED,
        PARAM_BRAKING,
        PARAM_PULL,
    };
    typedef QPair<MessageType, QStringRef> MessageTypeAndPayload;
    typedef QMap<MessageType, QString> MessagesByType;

    VescInterface *vesc;
    int aliveTimerId;
    int commandTimeoutTimerId;
    QElapsedTimer aliveResponseDelay;

    // Calculate average alive response
    const int avgN = 10;
    QVector<int> aliveResponseDelays;
    int aliveResponseDelayIndex;
    int sumAliveResponseDelay;
    int alivePings;

    QString lastCmd;

    QMLable_skypuff_config cfg;

    // Updated with SK_COMM_ALIVE
    smooth_motor_mode smoothMotorMode;
    QString motorModeText;
    int curTac;
    float erpm, amps, power;

    // Tons of regexps to parse terminal prints
    QRegExp reBraking, rePull, rePos, reSpeed, rePullingHigh;
    QRegExp reUnwindedFromSlowing, rePrePullTimeout, reMotionDetected;
    QRegExp reTakeoffTimeout;

    QString state;
    QString stateText;
    QString status;

    QHash<QString, int> h_states;
    QHash<MessageType, QString> messageTypes;

    // Getters
    bool isBrakingRange() const {return abs(curTac) <= cfg.braking_length;}
    bool isBrakingExtensionRange() const {return abs(curTac) <= cfg.braking_length + cfg.braking_extension_length;}
    float getRopeMeters() {return cfg.rope_length_to_meters();}
    float getDrawnMeters() {return cfg.tac_steps_to_meters(abs(curTac));}
    float getLeftMeters() {return cfg.tac_steps_to_meters(cfg.rope_length - abs(curTac));}
    float getSpeedMs() {return cfg.erpm_to_ms(erpm);}
    float getMotorKg() {return amps / cfg.amps_per_kg;}
    float getPower() {return power;}
    QString getState() {return state;}
    QString getStateText() {return stateText;}
    QString getStatus() {return status;}
    QString getMotorMode() {return motorModeText;}

    // Setters
    void setState(const QString& newState);
    void setStatus(const QString& mcuStatus);
    void setPos(const int new_pos);
    void setSpeed(const float new_erpm);
    void setMotor(const smooth_motor_mode newMode, const float newAmps, const float newPower);

    // Helpers
    bool sendCmd(const QString& cmd);
    void sendCmdOrDisconnect(const QString& cmd);
    void sendAlive(const int timeout);
    bool stopCommandTimeout(const QString& cmd);
    bool startCommandTimeout(const QString& cmd);
    void timerEvent(QTimerEvent *event) override;
    bool parseCommand(QStringRef &str, MessageTypeAndPayload &c);
    void processAlive(VByteArray &vb);
    void processSettingsV1(VByteArray &vb);
};

#endif // SKYPUFF_H
