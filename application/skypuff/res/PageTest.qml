import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.3

import SkyPuff.vesc.winch 1.0

import QtQml 2.2



Page {
    id: page
    state: "DISCONNECTED"

    // Get normal text color from this palette
    SystemPalette {id: systemPalette}

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        /**
          - Анимации закомменчены, выбери какю-нибудь
          - Нет проверок на адекватность переданных параметров
          - Некоторые моменты в коде дублируются
          - Возможно, нужно подкорректировать для мобилок
          - Переводы? хотя там нечего переводить
          */

        SkypuffGauge {
            speedMs: 22
            maxSpeedMs: 30
            ropeMeters: 333
            minRopeMeters: 0
            maxRopeMeters: 800
            power: -2
            maxPower: 20
            motorKg: 36
            minMotorKg: 0
            maxMotorKg: 150
            tempFets: 15
            tempMotor: 18
            tempBat: 20
            whIn: 0
            whOut: 0
            motorMode: 'Yoba mode'

            debug: true
        }
    }
}
