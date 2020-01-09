import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import SkyPuff.vesc.winch 1.0

Page {
    id: ctrl
    footer: Text {
        id: ft
        anchors.fill: parent

        text: "Hi"
    }

    states: [
        State {
            name: "DISCONNECTED"
            PropertyChanges { target: ft; text: "Disconnected" }
        },
        State {
            name: "UNITIALIZED"
            PropertyChanges { target: ft; text: "Unitialized" }
        }
    ]

    Connections {
        target: Skypuff

        onStateChanged: {
            ctrl.state = newState
        }
    }
}
