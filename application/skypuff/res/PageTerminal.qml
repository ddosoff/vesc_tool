/*
    Copyright 2018 - 2019 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

import SkyPuff.vesc.winch 1.0

Page {
    property Commands mCommands: VescIf.commands()

    function sendCommand() {
        mCommands.sendTerminalCmd(stringInput.text)
        stringInput.clear()
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 10
            contentWidth: terminalText.width
            clip: true

            TextArea {
                id: terminalText
                readOnly: true
                font.family: "DejaVu Sans Mono"
                font.pointSize: 10
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10

            TextInput {
                id: stringInput
                Layout.fillWidth: true
                focus: true
                cursorVisible: true

                onAccepted: {sendCommand()}
            }

            Button {
                text: qsTr("Send")
                enabled: Skypuff.state != "DISCONNECTED"

                onClicked: {sendCommand()}
            }
            Button {
                text: qsTr("Clear")

                onClicked: {
                    terminalText.clear()
                }
            }
       }
    }

    Connections {
        target: mCommands

        onPrintReceived: {
            terminalText.text += "\n" + str
            scroll.contentItem.contentY = terminalText.height - scroll.height
        }
    }
}
