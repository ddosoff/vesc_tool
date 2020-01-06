import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.bleuart 1.0
import Vedder.vesc.commands 1.0

Page {
    property BleUart mBle: VescIf.bleDevice()
    property Commands mCommands: VescIf.commands()
    property alias disconnectButton: disconnectButton

    function setConnectButtonsEnabled(e)
    {
        usbConnectButton.enabled = e
        bleConnectButton.enabled = e && (bleItems.rowCount() > 0)
    }

    PairingDialog {
        id: pairDialog
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        GroupBox {
            title: qsTr("Bluetooth")
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent

                GridLayout {
                    Layout.fillWidth: true

                    Button {
                        text: qsTr("Name")
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
                        text: qsTr("Pair")

                        onClicked: {
                            pairDialog.openDialog()
                        }
                    }

                    Button {
                        id: scanButton
                        text: qsTr("Scan")

                        onClicked: {
                            scanButton.enabled = false
                            mBle.startScan()
                        }
                    }
                }

                ComboBox {
                    id: bleBox
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    textRole: "key"
                    model: ListModel {
                        id: bleItems
                    }
                }

                Button {
                    id: bleConnectButton
                    text: qsTr("Connect")
                    enabled: false
                    //Layout.preferredWidth: 500
                    Layout.fillWidth: true

                    onClicked: {
                        if (bleItems.rowCount() > 0) {
                            setConnectButtonsEnabled(false)
                            VescIf.connectBle(bleItems.get(bleBox.currentIndex).value)
                        }
                    }
                }
            }

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

                    bleConnectButton.enabled = (bleItems.rowCount() > 0) && !VescIf.isPortConnected()

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

                /*
                Timer {
                    interval: 100
                    running: true
                    repeat: true

                    onTriggered: {
                        setConnectButtonsEnabled((bleItems.rowCount() > 0) && !VescIf.isPortConnected() && !mBle.isConnecting())
                        disconnectButton.enabled = VescIf.isPortConnected()
                    }
                }
                */
            }
        }

        GroupBox {
            title: qsTr("USB/Serial")
            Layout.fillWidth: true

            GridLayout {
                anchors.fill: parent

                rowSpacing: 5
                columnSpacing: 5

                Button {
                    id: usbConnectButton
                    Layout.fillWidth: true
                    text: qsTr("Auto Connect")

                    onClicked: {
                        VescIf.autoconnect()
                        setConnectButtonsEnabled(false)
                    }
                }

            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Button {
                id: disconnectButton
                text: qsTr("Disconnect")

                anchors.centerIn: parent
                enabled: false

                onClicked: {
                    VescIf.disconnectPort()
                }
            }
        }

        Label {
            id: vescMessage

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight

            text: qsTr("Not connected")
            color: "red"
        }
    }

    Connections {
        target: VescIf

        onPortConnectedChanged: {
            if(VescIf.isPortConnected()) {
                setConnectButtonsEnabled(false)
                disconnectButton.enabled = true
            }
            else {
                setConnectButtonsEnabled(true)
                disconnectButton.enabled = false
                vescMessage.text = qsTr("Not connected")
                vescMessage.color = "red"
            }
        }

        onStatusMessage: {
            vescMessage.text = msg
            vescMessage.color = isGood ? "green" : "red"
        }
    }
}
