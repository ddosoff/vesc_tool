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

    // Skypuff MCU connected?
    //Q_PROPERTY(bool isSkypuffConnected READ isConnected NOTIFY connectedChanged)

    // I tried to make enum skypuff_state QML accesible, but ..
    Q_PROPERTY(QString state READ getState NOTIFY stateChanged)
    Q_PROPERTY(QString status READ getStatus NOTIFY statusChanged)

    // Enable back to braking from unwinding in the braking extension zone
    Q_PROPERTY(bool isBrakingExtensionRange READ isBrakingExtensionRange NOTIFY brakingExtensionRangeChanged)
    Q_PROPERTY(float pos_meters READ getPosMeters NOTIFY posChanged)
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
    void stateChanged(const QString& newState, const QVariantMap& params);
    void settingsChanged(const QMLable_skypuff_config & cfg);
    void statusChanged(const QString &status);
    void brakingExtensionRangeChanged(const bool isBrakingExtensionRange);
    void posChanged(const float meters);
    void speedChanged(const float ms);
protected:
    // Parsed messages from prints
    enum MessageType {
        TEXT_MESSAGE,
        POSITION,
        SPEED,
        BRAKING,
        PULL,
    };
    typedef QPair<MessageType, QStringRef> MessageTypeAndPayload;
    typedef QPair<QString, MessageType> StrMessageType;

    VescInterface *vesc;
    int aliveTimerId;
    int commandTimeoutTimerId;
    QString lastCmd;

    QMLable_skypuff_config cfg;
    int pos;
    float erpm;
    QString status;

    QString getState() {return m_state;}
    QString getStatus() {return status;}
    void setState(const QString& newState, const QVariantMap& params = QVariantMap());
    bool sendCmd(const QString& cmd);
    void sendCmdOrDisconnect(const QString& cmd);
    bool stopTimout(const QString& cmd);
    void timerEvent(QTimerEvent *event) override;
    bool parseCommand(QStringRef &str, MessageTypeAndPayload &c);

    void setStatus(const QString& mcuStatus);
    void setPos(const int new_pos, const bool ovverideChanged = false);
    void setSpeed(float new_erpm);
    bool isBrakingExtensionRange() const {return pos > cfg.braking_length && pos <= cfg.braking_length + cfg.braking_extension_length;}
    float getPosMeters() {return cfg.tac_steps_to_meters(pos);}
    float getSpeedMs() {return cfg.erpm_to_ms(erpm);}
protected slots:
    void printReceived(QString str);
    void customAppDataReceived(QByteArray data);
    void portConnectedChanged();
private:
    QRegExp rePos, reSpeed;
    QString m_state;
    QHash<QString, int> h_states; // Dirty hack about skypuff_states enum
    QHash<MessageType, QString> messageTypes;
};

#endif // SKYPUFF_H
