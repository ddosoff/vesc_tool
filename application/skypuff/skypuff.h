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

#include "vescinterface.h"
#include "qmlable_skypuff_types.h"

const int aliveTimerDelay = 300; // milliseconds
const int aliveTimeout = 400;
const int commandTimeout = 400;


/*
 * After vesc is connected, Skypuff will ask configuration and
 * will starts sending alive commands.
 *
 * Received MCU terminal prints will be parsed, CUSTOM_APP_DATA
 * deserialized and translated to QML accessible properties and signals.
 *
 * Sorry for some hardcore stings parsing.
 * It's not too bad in the end.
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
    Q_PROPERTY(float rope_meters READ getRopeMeters NOTIFY settingsChanged)
    Q_PROPERTY(float drawn_meters READ getDrawnMeters NOTIFY posChanged)
    Q_PROPERTY(float left_meters READ getLeftMeters NOTIFY posChanged)
    Q_PROPERTY(float speed_ms READ getSpeedMs NOTIFY speedChanged)
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
    void posChanged(const float meters);
    void speedChanged(const float ms);
protected slots:
    void printReceived(QString str);
    void customAppDataReceived(QByteArray data);
    void portConnectedChanged();
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
    QString lastCmd;

    QMLable_skypuff_config cfg;
    int cur_tac; // Signed tachometer value
    float erpm;
    QString status;

    // Tons of regexps to parse terminal prints
    QRegExp reBraking, rePull, rePos, reSpeed, rePullingHigh;
    QRegExp reUnwindedFromSlowing, rePrePullTimeout, reMotionDetected;
    QRegExp reTakeoffTimeout;

    QString state;
    QString stateText;

    QHash<QString, int> h_states;
    QHash<MessageType, QString> messageTypes;

    // Getters
    bool isBrakingExtensionRange() const {return abs(cur_tac) <= cfg.braking_length + cfg.braking_extension_length;}
    float getRopeMeters() {return cfg.rope_length_to_meters();}
    float getDrawnMeters() {return cfg.tac_steps_to_meters(abs(cur_tac));}
    float getLeftMeters() {return cfg.tac_steps_to_meters(cfg.rope_length - abs(cur_tac));}
    float getSpeedMs() {return cfg.erpm_to_ms(erpm);}
    QString getState() {return state;}
    QString getStateText() {return stateText;}
    QString getStatus() {return status;}

    // Setters
    void setState(const QString& newState);
    void setStatus(const QString& mcuStatus);
    void setPos(const int new_pos, const bool ovverideChanged = false);
    void setSpeed(float new_erpm);

    // Helpers
    bool sendCmd(const QString& cmd);
    void sendCmdOrDisconnect(const QString& cmd);
    bool stopTimout(const QString& cmd);
    void timerEvent(QTimerEvent *event) override;
    bool parseCommand(QStringRef &str, MessageTypeAndPayload &c);

};

#endif // SKYPUFF_H
