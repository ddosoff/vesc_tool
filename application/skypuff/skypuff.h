#ifndef SKYPUFF_H
#define SKYPUFF_H

#include "vescinterface.h"

class Skypuff : public QObject
{
    Q_OBJECT
public:
    Skypuff(VescInterface *parent = 0);
private slots:
    void portConnectedChanged();
private:
    VescInterface *vesc;
};

#endif // SKYPUFF_H
