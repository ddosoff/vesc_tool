import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.3

import SkyPuff.vesc.winch 1.0
import QtQml 2.2



Page {
    id: page1
    state: "DISCONNECTED"

    // Get normal text color from this palette
    SystemPalette {id: systemPalette; colorGroup: SystemPalette.Active}

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
            id: sGauhe
            speedMs: Skypuff.speedMs

            ropeMeters: Skypuff.ropeMeters
            leftRopeMeters :Skypuff.leftMeters
            power: Skypuff.power
            motorKg: Skypuff.motorKg
            motorMode: Skypuff.motorMode

            maxRopeMeters: 1500
            //maxPower: cfg.power_max
            //maxMotorKg: cfg.motor_max_kg

            /*tempFets: 15
            tempMotor: 18
            tempBat: 20
            whIn: 0
            whOut: 0*/

            /**
            pullForce.to = cfg.motor_max_kg
            pullForce.stepSize = cfg.motor_max_kg / 30
            pullForce.value = cfg.pull_kg

            pbMotor.to = cfg.motor_max_kg
            pbPower.to = cfg.power_
*/


            debug: false
        }         
    }
    Connections {
        target: Skypuff

        onSettingsChanged: {
            sGauhe.maxMotorKg = cfg.motor_max_kg
            sGauhe.maxPower = cfg.power_max
        }
    }

}
