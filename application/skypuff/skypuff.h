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

#include <math.h>
#include <QObject>

#include "vescinterface.h"
#include "app_skypuff.h"

// Make settings accesible to QML with on the fly units conversions
struct QMLable_skypuff_config : public skypuff_config, public skypuff_drive {
    Q_GADGET

    Q_PROPERTY(int motor_poles MEMBER motor_poles)
    Q_PROPERTY(int wheel_diameter_mm READ wheel_diameter_to_mm WRITE wheel_diameter_from_mm)
    Q_PROPERTY(float gear_ratio MEMBER gear_ratio)
    Q_PROPERTY(float amps_per_kg MEMBER amps_per_kg)
    Q_PROPERTY(float kg_per_sec READ amps_per_sec_to_kg WRITE kg_per_sec_to_amps)
    Q_PROPERTY(float rope_length_meters READ rope_length_to_meters WRITE meters_to_rope_length)
    Q_PROPERTY(float braking_length_meters READ braking_length_to_meters WRITE meters_to_braking_length)
    Q_PROPERTY(float braking_extension_length_meters READ braking_extension_length_to_meters WRITE meters_to_braking_extension_length)
    Q_PROPERTY(float slowing_length_meters READ slowing_length_to_meters WRITE meters_to_slowing_length)
    Q_PROPERTY(float slow_erpm_ms READ slow_erpm_to_ms WRITE ms_to_slow_erpm)
    Q_PROPERTY(float rewinding_trigger_length_meters READ rewinding_trigger_length_to_meters WRITE meters_to_rewinding_trigger_length)
    Q_PROPERTY(float unwinding_trigger_length_meters READ unwinding_trigger_length_to_meters WRITE meters_to_unwinding_trigger_length)
    Q_PROPERTY(float pull_kg READ pull_current_to_kg WRITE kg_to_pull_current)
    Q_PROPERTY(int pre_pull_k_percents READ pre_pull_k_to_percents WRITE percents_to_pre_pull_k)
    Q_PROPERTY(int takeoff_pull_k_percents READ takeoff_pull_k_to_percents WRITE percents_to_takeoff_pull_k)
    Q_PROPERTY(int fast_pull_k_percents READ fast_pull_k_to_percents WRITE percents_to_fast_pull_k)
    Q_PROPERTY(float takeoff_trigger_length_meters READ takeoff_trigger_length_to_meters WRITE meters_to_takeoff_trigger_length)
    Q_PROPERTY(float pre_pull_timeout_seconds READ pre_pull_timeout_to_seconds WRITE seconds_to_pre_pull_timeout)
    Q_PROPERTY(float takeoff_period_seconds  READ takeoff_period_to_seconds WRITE seconds_to_takeoff_period)
    Q_PROPERTY(float brake_kg READ brake_current_to_kg WRITE kg_to_brake_current)
    Q_PROPERTY(float slowing_kg READ slowing_current_to_kg WRITE kg_to_slowing_current)
    Q_PROPERTY(float manual_brake_kg READ manual_brake_current_to_kg WRITE kg_to_manual_brake_current)
    Q_PROPERTY(float unwinding_kg READ unwinding_current_to_kg WRITE kg_to_unwinding_current)
    Q_PROPERTY(float rewinding_kg READ rewinding_current_to_kg WRITE kg_to_rewinding_current)
    Q_PROPERTY(float slow_max_kg READ slow_max_current_to_kg WRITE kg_to_slow_max_current)
    Q_PROPERTY(float manual_slow_max_kg READ manual_slow_max_current_to_kg WRITE kg_to_manual_slow_max_current)
    Q_PROPERTY(float manual_slow_speed_up_kg READ manual_slow_speed_up_current_to_kg WRITE kg_to_manual_slow_speed_up_current)
    Q_PROPERTY(float manual_slow_erpm_ms READ manual_slow_erpm_to_ms WRITE ms_to_manual_slow_erpm)

public:
    int wheel_diameter_to_mm() {return round(wheel_diameter * (float)1000);}
    void wheel_diameter_from_mm(int mm) {wheel_diameter = (float)mm / (float)1000;}

    int pre_pull_k_to_percents() {return round(pre_pull_k * (float)100);}
    void percents_to_pre_pull_k(int p) {pre_pull_k = (float)p / (float)100;}

    int takeoff_pull_k_to_percents() {return round(takeoff_pull_k * (float)100);}
    void percents_to_takeoff_pull_k(int p) {takeoff_pull_k = (float)p / (float)100;}

    int fast_pull_k_to_percents() {return round(fast_pull_k * (float)100);}
    void percents_to_fast_pull_k(int p) {fast_pull_k = (float)p / (float)100;}

    float pre_pull_timeout_to_seconds() {return pre_pull_timeout / (float)1000;}
    void seconds_to_pre_pull_timeout(float secs) {pre_pull_timeout = round(secs * (float)1000);}

    float takeoff_period_to_seconds() {return takeoff_period / (float)1000;}
    void seconds_to_takeoff_period(float secs) {takeoff_period = round(secs * (float)1000);}

    float amps_per_sec_to_kg() {return amps_per_sec / amps_per_kg;}
    void kg_per_sec_to_amps(float kg) {amps_per_sec = kg * amps_per_kg;}

    float pull_current_to_kg() {return pull_current / amps_per_kg;}
    void kg_to_pull_current(float kg) {pull_current = kg * amps_per_kg;}

    float brake_current_to_kg() {return brake_current / amps_per_kg;}
    void kg_to_brake_current(float kg) {brake_current = kg * amps_per_kg;}

    float manual_brake_current_to_kg() {return manual_brake_current / amps_per_kg;}
    void kg_to_manual_brake_current(float kg) {manual_brake_current = kg * amps_per_kg;}

    float unwinding_current_to_kg() {return unwinding_current / amps_per_kg;}
    void kg_to_unwinding_current(float kg) {unwinding_current = kg * amps_per_kg;}

    float rewinding_current_to_kg() {return rewinding_current / amps_per_kg;}
    void kg_to_rewinding_current(float kg) {rewinding_current = kg * amps_per_kg;}

    float slowing_current_to_kg() {return slowing_current / amps_per_kg;}
    void kg_to_slowing_current(float kg) {slowing_current = kg * amps_per_kg;}

    float slow_max_current_to_kg() {return slow_max_current / amps_per_kg;}
    void kg_to_slow_max_current(float kg) {slow_max_current = kg * amps_per_kg;}

    float manual_slow_max_current_to_kg() {return manual_slow_max_current / amps_per_kg;}
    void kg_to_manual_slow_max_current(float kg) {manual_slow_max_current = kg * amps_per_kg;}

    float manual_slow_speed_up_current_to_kg() {return manual_slow_speed_up_current / amps_per_kg;}
    void kg_to_manual_slow_speed_up_current(float kg) {manual_slow_speed_up_current = kg * amps_per_kg;}

    float rope_length_to_meters() {return tac_steps_to_meters(rope_length);}
    void meters_to_rope_length(float meters) {rope_length = meters_to_tac_steps(meters);}

    float braking_length_to_meters() {return tac_steps_to_meters(braking_length);}
    void meters_to_braking_length(float meters) {braking_length = meters_to_tac_steps(meters);}

    float braking_extension_length_to_meters() {return tac_steps_to_meters(braking_extension_length);}
    void meters_to_braking_extension_length(float meters) {braking_extension_length = meters_to_tac_steps(meters);}

    float slowing_length_to_meters() {return tac_steps_to_meters(slowing_length);}
    void meters_to_slowing_length(float meters) {slowing_length = meters_to_tac_steps(meters);}

    float rewinding_trigger_length_to_meters() {return tac_steps_to_meters(rewinding_trigger_length);}
    void meters_to_rewinding_trigger_length(float meters) {rewinding_trigger_length = meters_to_tac_steps(meters);}

    float unwinding_trigger_length_to_meters() {return tac_steps_to_meters(unwinding_trigger_length);}
    void meters_to_unwinding_trigger_length(float meters) {unwinding_trigger_length = meters_to_tac_steps(meters);}

    float takeoff_trigger_length_to_meters() {return tac_steps_to_meters(takeoff_trigger_length);}
    void meters_to_takeoff_trigger_length(float meters) {takeoff_trigger_length = meters_to_tac_steps(meters);}

    float slow_erpm_to_ms() {return erpm_to_ms(slow_erpm);}
    void ms_to_slow_erpm(float ms) {slow_erpm = ms_to_erpm(ms);}

    float manual_slow_erpm_to_ms() {return erpm_to_ms(manual_slow_erpm);}
    void ms_to_manual_slow_erpm(float ms) {manual_slow_erpm = ms_to_erpm(ms);}

    inline float meters_per_rev() {return wheel_diameter / gear_ratio * M_PI;}
    inline float steps_per_rev(void) {return motor_poles * 3;}
    inline int meters_to_tac_steps(float meters) {return round(meters / meters_per_rev() * steps_per_rev());}
    inline float tac_steps_to_meters(int steps) {return (float)steps / steps_per_rev() * meters_per_rev();}
    inline float ms_to_erpm(float ms)
    {
        float rps = ms / meters_per_rev();
        float rpm = rps * 60;

        return rpm * (motor_poles / 2);
    }
    inline float erpm_to_ms(float erpm)
    {
        float erps = erpm / 60;
        float rps = erps / (motor_poles / 2);

        return rps * meters_per_rev();
    }
};

Q_DECLARE_METATYPE(QMLable_skypuff_config)

/*
 * After vesc is connected, Skypuff will start
 * sending alive commands and ask for configuration and state.
 *
 * If no answer within commandTimeout, vesc will be disconnected
 * and error message thrown via vesc interface.
 */
class Skypuff : public QObject
{
    Q_OBJECT

    // Do we really need to divide state into many properties?
    Q_PROPERTY(QString state READ getState NOTIFY stateChanged)

    const int aliveTimerDelay = 300; // milliseconds
    const int aliveTimeout = 400;
    const int commandTimeout = 400;
public:
    Skypuff(VescInterface *parent = 0);

    // QML settings constructor
    Q_INVOKABLE QMLable_skypuff_config emptySettings() {return QMLable_skypuff_config();}
    Q_INVOKABLE void saveSettings(const QMLable_skypuff_config& cfg);
    Q_INVOKABLE void sendTerminal(const QString &c) {vesc->commands()->sendTerminalCmd(c);}

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
signals:
    /* It is simple to work with QML text states:
     *
     * DISCONNECTED - VESC is disconnected or connected but state not detected yet
     * UNITIALIZED - Skypuff app is waiting for correct settings
     * BRAKING .. and all skypuff states
     */
    void stateChanged(const QString& newState, const QVariantMap& params);
    void settingsChanged(const QMLable_skypuff_config &cfg);
    void statsChanged(const float cur_pos_meters, const float speed_ms);

    // Parsed messages from MCU
    void statusMessage(const QString &msg);
    // Will be emited vescinterface message dialog
    //void alarmMessage(const QString& title, const QString &msg);
protected:
    VescInterface *vesc;
    int aliveTimerId;
    int commandTimeoutTimerId;
    QString lastCmd;

    QString getState() {return m_state;}
    void setState(const QString& newState, const QVariantMap& params = QVariantMap());
    bool sendCmd(const QString& cmd);
    void sendCmdOrDisconnect(const QString& cmd);
    bool stopTimout(const QString& cmd);
    void timerEvent(QTimerEvent *event) override;
    bool parseCommand(QStringRef &str, MessageTypeAndPayload &c);
protected slots:
    void printReceived(QString str);
    void customAppDataReceived(QByteArray data);
    void portConnectedChanged();
private:
    QString m_state;
    QHash<QString, int> h_states; // Dirty hack about skypuff_states enum
    QHash<MessageType, QString> messageTypes;

    // Sorry for hardcoded serialization..
    void deserializeV1(VByteArray & vb);
    QByteArray serializeV1(const QMLable_skypuff_config & cfg);
};

#endif // SKYPUFF_H
