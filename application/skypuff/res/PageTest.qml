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

        //ProgressCircle{}

        SkypuffGauge {
            //diameter: 800
            //power: 137.5654
            speedMs: 50
            minSpeedMs: 20
            maxSpeedMs: 120
            ropeMeters: 500
            minRopeMeters: 0
            maxRopeMeters: 800
            /*ropeMeters: 100
            leftMeters: 700
            motorMode: "Test test"*/
        }
    }
}
