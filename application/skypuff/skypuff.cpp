#include "skypuff.h"

Skypuff::Skypuff(VescInterface *parent) : QObject(parent), vesc(parent)
{
    connect(vesc, SIGNAL(portConnectedChanged()), this, SLOT(portConnectedChanged()));
}

void Skypuff::portConnectedChanged()
{
    qWarning() << "Skypuff::portConnectedChanged():" << vesc->isPortConnected();
}
