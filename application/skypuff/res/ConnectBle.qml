/*
    Copyright 2017 - 2019 Benjamin Vedder	benjamin@vedder.se

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
import Vedder.vesc.bleuart 1.0
import Vedder.vesc.commands 1.0

Item {
    id: topItem

    property BleUart mBle: VescIf.bleDevice()
    property Commands mCommands: VescIf.commands()
    property alias disconnectButton: disconnectButton
    property bool isHorizontal: width > height
    signal requestOpenControls()

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: isHorizontal ? 2 : 1
        columnSpacing: 5
        rowSpacing: 10

        GroupBox {
            id: bleConnBox
            title: qsTr("BLE Connection")
            Layout.fillWidth: true
            Layout.columnSpan: 1

            GridLayout {
                anchors.topMargin: -5
                anchors.bottomMargin: -5
                anchors.fill: parent

                clip: false
                visible: true
                rowSpacing: -10
                columnSpacing: 5
                rows: 5
                columns: 6

                Button {
                    id: setNameButton
                    text: qsTr("Name")
                    Layout.columnSpan: 2
                    Layout.preferredWidth: 500
                    Layout.fillWidth: true
                    enabled: bleBox.count > 0

                    onClicked: {
                        if (bleItems.rowCount() > 0) {
                            bleNameDialog.open()
                        } else {
                            VescIf.emitMessageDialog("Set BLE Device Name",
                                                     "No device selected.",
                                                     false, false);
                        }
                    }
                }

                Button {
                    text: "Pair"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 500
                    Layout.columnSpan: 2

                    onClicked: {
                        pairDialog.openDialog()
                    }
                }

                Button {
                    id: scanButton
                    text: qsTr("Scan")
                    Layout.columnSpan: 2
                    Layout.preferredWidth: 500
                    Layout.fillWidth: true

                    onClicked: {
                        scanButton.enabled = false
                        mBle.startScan()
                    }
                }

                ComboBox {
                    id: bleBox
                    Layout.columnSpan: 6
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    transformOrigin: Item.Center

                    textRole: "key"
                    model: ListModel {
                        id: bleItems
                    }
                }

                Button {
                    id: disconnectButton
                    text: qsTr("Disconnect")
                    enabled: false
                    Layout.preferredWidth: 500
                    Layout.fillWidth: true
                    Layout.columnSpan: 3

                    onClicked: {
                        VescIf.disconnectPort()
                    }
                }

                Button {
                    id: connectButton
                    text: qsTr("Connect")
                    enabled: false
                    Layout.preferredWidth: 500
                    Layout.fillWidth: true
                    Layout.columnSpan: 3

                    onClicked: {
                        if (bleItems.rowCount() > 0) {
                            connectButton.enabled = false
                            VescIf.connectBle(bleItems.get(bleBox.currentIndex).value)
                        }
                    }
                }
            }
        }
    }

    /*
    Timer {
        interval: 500
        running: !scanButton.enabled
        repeat: true

        property int dots: 0
        onTriggered: {
            var text = "S"
            for (var i = 0;i < dots;i++) {
                text = "-" + text + "-"
            }

            dots++;
            if (dots > 3) {
                dots = 0;
            }

            scanButton.text = text
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true

        onTriggered: {
            connectButton.enabled = (bleItems.rowCount() > 0) && !VescIf.isPortConnected() && !mBle.isConnecting()
            disconnectButton.enabled = VescIf.isPortConnected()
        }
    }*/

    Connections {
        target: mBle
        onScanDone: {
            if (done) {
                scanButton.enabled = true
                scanButton.text = qsTr("Scan")
            }

            bleItems.clear()

            for (var addr in devs) {
                var name = devs[addr]
                var name2 = name + " [" + addr + "]"
                var setName = VescIf.getBleName(addr)
                if (setName.length > 0) {
                    setName += " [" + addr + "]"
                    bleItems.insert(0, { key: setName, value: addr })
                } else if (name.indexOf("VESC") !== -1) {
                    bleItems.insert(0, { key: name2, value: addr })
                } else {
                    bleItems.append({ key: name2, value: addr })
                }
            }

            connectButton.enabled = (bleItems.rowCount() > 0) && !VescIf.isPortConnected()

            bleBox.currentIndex = 0
        }

        onBleError: {
            VescIf.emitMessageDialog("BLE Error", info, false, false)
        }
    }

    Connections {
        target: mCommands

        onPingCanRx: {
            canItems.clear()
            for (var i = 0;i < devs.length;i++) {
                var name = "VESC " + devs[i]
                canItems.append({ key: name, value: devs[i] })
            }
            canScanButton.enabled = true
            canAllButton.enabled = true
            canIdBox.currentIndex = 0
            canButtonLayout.visible = true
            canScanBar.visible = false
            canScanBar.indeterminate = false
        }

        onNrfPairingRes: {
            if (res != 0) {
                nrfPairButton.visible = true
            }
        }
    }

    Dialog {
        id: bleNameDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        title: "Set BLE Device Name"

        width: parent.width - 20
        height: 200
        closePolicy: Popup.CloseOnEscape
        x: 10
        y: Math.max(parent.height / 4 - height / 2, 20)
        parent: ApplicationWindow.overlay

        Rectangle {
            anchors.fill: parent
            height: stringInput.implicitHeight + 14
            border.width: 2
            border.color: "#8d8d8d"
            color: "#33a8a8a8"
            radius: 3
            TextInput {
                id: stringInput
                color: "#ffffff"
                anchors.fill: parent
                anchors.margins: 7
                font.pointSize: 12
                focus: true
            }
        }

        onAccepted: {
            if (stringInput.text.length > 0) {
                var addr = bleItems.get(bleBox.currentIndex).value
                var setName = stringInput.text + " [" + addr + "]"

                VescIf.storeBleName(addr, stringInput.text)
                VescIf.storeSettings()

                bleItems.set(bleBox.currentIndex, { key: setName, value: addr })
                bleBox.currentText
            }
        }
    }
}
