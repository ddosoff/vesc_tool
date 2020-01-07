#ifndef SKYPUFF_H
#define SKYPUFF_H

#include "vescinterface.h"
#include "app_skypuff.h"

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

    const int aliveTimerDelay = 300; // milliseconds
    const int aliveTimeout = 400;
    const int commandTimeout = 400;
public:
    Skypuff(VescInterface *parent = 0);
signals:
    /* It is simple to work with QML text states:
     *
     * DISCONNECTED - VESC is disconnected or state not detected yet
     * UNITIALIZED - Skypuff app is waiting for correct settings
     * BRAKING .. and all skypuff states
     */
    void newState(const QString& newState);
protected:
    VescInterface *vesc;
    int aliveTimerId;
    int commandTimeoutTimerId;
    QString lastCmd;

    skypuff_state state;
    int cur_pos;
    skypuff_drive drive_cfg;
    skypuff_config skypuff_cfg;

    bool sendCmd(const QString& cmd);
    void sendCmdOrDisconnect(const QString& cmd);
    bool stopTimout(const QString& cmd);
    void timerEvent(QTimerEvent *event) override;
protected slots:
    void printReceived(QString str);
    void customAppDataReceived(QByteArray data);
    void portConnectedChanged();
};

#endif // SKYPUFF_H
