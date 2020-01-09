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
    Q_PROPERTY(int rope_length MEMBER rope_length)
    Q_PROPERTY(int braking_length_meters READ braking_length_to_meters WRITE meters_to_braking_length)
    Q_PROPERTY(int passive_braking_length MEMBER passive_braking_length)
    Q_PROPERTY(int slowing_length MEMBER slowing_length)
    Q_PROPERTY(float slow_erpm MEMBER slow_erpm)
    Q_PROPERTY(int rewinding_trigger_length MEMBER rewinding_trigger_length)
    Q_PROPERTY(int unwinding_trigger_length MEMBER unwinding_trigger_length)
    Q_PROPERTY(float pull_current MEMBER pull_current)
    Q_PROPERTY(float pre_pull_k MEMBER pre_pull_k)
    Q_PROPERTY(float takeoff_pull_k MEMBER takeoff_pull_k)
    Q_PROPERTY(float fast_pull_k MEMBER fast_pull_k)
    Q_PROPERTY(int takeoff_trigger_length MEMBER takeoff_trigger_length)
    Q_PROPERTY(int pre_pull_timeout MEMBER pre_pull_timeout)
    Q_PROPERTY(int takeoff_period MEMBER takeoff_period)
    Q_PROPERTY(float brake_current MEMBER brake_current)
    Q_PROPERTY(float slowing_current MEMBER slowing_current)
    Q_PROPERTY(float manual_brake_current MEMBER manual_brake_current)
    Q_PROPERTY(float unwinding_current MEMBER unwinding_current)
    Q_PROPERTY(float rewinding_current MEMBER rewinding_current)
    Q_PROPERTY(float slow_max_current MEMBER slow_max_current)
    Q_PROPERTY(float manual_slow_max_current MEMBER manual_slow_max_current)
    Q_PROPERTY(float manual_slow_speed_up_current MEMBER manual_slow_speed_up_current)
    Q_PROPERTY(float manual_slow_erpm MEMBER manual_slow_erpm)

public:
    int wheel_diameter_to_mm() {return round(wheel_diameter * (float)1000);}
    void wheel_diameter_from_mm(int mm) {
        wheel_diameter = (float)mm / (float)1000;
    }

    float amps_per_sec_to_kg() {return amps_per_sec / amps_per_kg;}
    void kg_per_sec_to_amps(float kg) {amps_per_sec = kg * amps_per_kg;}

    float braking_length_to_meters() {return tac_steps_to_meters(braking_length);}
    void meters_to_braking_length(float meters) {braking_length = meters_to_tac_steps(meters);}

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
    Q_PROPERTY(QString m_state READ getState NOTIFY stateChanged)

    const int aliveTimerDelay = 300; // milliseconds
    const int aliveTimeout = 400;
    const int commandTimeout = 400;
public:
    Skypuff(VescInterface *parent = 0);

    // QML settings constructor
    Q_INVOKABLE QMLable_skypuff_config emptySettings() {return QMLable_skypuff_config();}
    Q_INVOKABLE void saveSettings(const QMLable_skypuff_config& cfg);
signals:
    /* It is simple to work with QML text states:
     *
     * DISCONNECTED - VESC is disconnected or connected but state not detected yet
     * UNITIALIZED - Skypuff app is waiting for correct settings
     * BRAKING .. and all skypuff states
     */
    void stateChanged(const QString& newState);
    void settingsChanged(const QMLable_skypuff_config &cfg);
    void statsChanged(const float cur_pos_meters, const float speed_ms);
protected:
    VescInterface *vesc;
    int aliveTimerId;
    int commandTimeoutTimerId;
    QString lastCmd;

    QString getState() {return m_state;}
    void setState(const QString& newState);
    bool sendCmd(const QString& cmd);
    void sendCmdOrDisconnect(const QString& cmd);
    bool stopTimout(const QString& cmd);
    void timerEvent(QTimerEvent *event) override;
protected slots:
    void printReceived(QString str);
    void customAppDataReceived(QByteArray data);
    void portConnectedChanged();
private:
    QString m_state;

    // Sorry for hardcoded serialization..
    void deserializeV1(VByteArray & vb);
    QByteArray serializeV1(const QMLable_skypuff_config & cfg);
};

#endif // SKYPUFF_H
