import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.bleuart 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

Page {
    id: page
    property BleUart mBle: VescIf.bleDevice()
    property Commands mCommands: VescIf.commands()
    property ConfigParams mInfoConf: VescIf.infoConfig()
    //property alias disconnectButton: disconnectButton

    function setConnectButtonsEnabled(e)
    {
        usbConnectButton.enabled = e
        bleConnectButton.enabled = e && (bleItems.rowCount() > 0)
    }

    function updateConnected()
    {
        if(VescIf.isPortConnected()) {
            setConnectButtonsEnabled(false)
            disconnectButton.enabled = true
        }
        else {
            setConnectButtonsEnabled(true)
            disconnectButton.enabled = false
            statusMessage.text = qsTr("Not connected")
            statusMessage.color = "red"
        }
    }

    /*PairingDialog {
        id: pairDialog
    }*/

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Label {
            text: qsTr("Find Skypuff")

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 16
            font.bold: true
            Layout.topMargin: 15
        }

        // Methods buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10

            Item {
                Layout.fillWidth: true
            }

            BigRoundButton {
                id: bBluetooth
                icon.source: "qrc:/res/icons/bluetooth.svg"
                Material.foreground: Material.Blue
                onClicked: bBluetooth.busy = !bBluetooth.busy
            }

            BigRoundButton {
                id: bUsb
                //Layout.margins: parent.width / 20
                icon.source: "qrc:/res/icons/usb.svg"
                iconPercent: 40
                Material.foreground: Material.Teal
            }
            BigRoundButton {
                id: bWifi
                icon.source: "qrc:/res/icons/wifi.svg"
                Material.foreground: Material.Indigo
            }
            Item {
                Layout.fillWidth: true
            }

            Component.onCompleted: {
                bBluetooth.size = page.width / 4
                bUsb.size = bBluetooth.size
                bWifi.size = bBluetooth.size
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 20
            Layout.topMargin: 20
            ScrollBar.vertical: ScrollBar {}

            delegate: Item {
                id: delegateItem
                width: listView.width
                clip: true
                Text {
                    id: tW
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: addr
                    //x: listView.width / 2 - 200 / 2
                }
                // indent the item if it is the current item
                states: State {
                    name: "Current"
                    when: delegateItem.ListView.isCurrentItem
                    PropertyChanges { target: tW; x: 20; font.bold: true }
                }
                /*transitions: Transition {
                    NumberAnimation { properties: "x"; duration: 200 }
                }*/
                MouseArea {
                    anchors.fill: parent
                    onClicked: delegateItem.ListView.view.currentIndex = index
                }

                ListView.onAdd: SequentialAnimation {
                    PropertyAction { target: delegateItem; property: "height"; value: 0 }
                    NumberAnimation { target: delegateItem; property: "height"; to: tW.implicitHeight * 2; duration: 400; easing.type: Easing.InOutQuad }
                }
            }

            model: ListModel {
                id: listModel
            }
            highlight: Rectangle {
                width: 180; height: 20
                color: "lightsteelblue"; radius: 5
                y: listView.currentItem ? listView.currentItem.y : 0
                Behavior on y {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }
            }
            clip: true
            highlightFollowsCurrentItem: false
            focus: true

            Component.onCompleted: {
                listModel.append({addr: "bt://45.32.34.54.34.43"})
                listModel.append({addr: "bt://15.52.24.24.65.34"})
                listModel.append({addr: "usb://ttyACME0"})
                listModel.append({addr: "tcp://234.32.123.64"})
                listView.currentIndex = -1
            }
        }
    }
}

        /*
        Button {
            text: "Add"

            onClicked: {
                listModel.append({addr: Math.random()})
                listView.currentIndex = -1
            }
        }

        Label {
            text: "Index: %1".arg(listView.currentIndex)
        }

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
                            var b = bleItems.get(bleBox.currentIndex).value
                            statusMessage.text = "Connecting BlueTooth: " + b + " ..."
                            statusMessage.color = "blue"

                            VescIf.connectBle(b)
                            bleChecker.running = true
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
                        // UI changes have to be done before trying to connect
                        setConnectButtonsEnabled(false)
                        statusMessage.text = "Connecting USB/Serial..."
                        statusMessage.color = "blue"

                        VescIf.autoconnect()
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
            id: statusMessage

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight

            text: qsTr("Not connected")
            color: "red"
        }

    }
    Dialog {
        id: vescDialog
        standardButtons: Dialog.Ok
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape

        width: parent.width - 20
        height: Math.min(implicitHeight, parent.height - 40)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        parent: ApplicationWindow.overlay

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: parent.width - 20

            Text {
                id: vescDialogLabel
                linkColor: "lightblue"
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }
        }
    }

    Connections {
        target: VescIf

        // Display modal dialog with errors from VESC interface
        onMessageDialog: {
            vescDialog.title = title
            vescDialogLabel.text = (richText ? "<style>a:link { color: lightblue; }</style>" : "") + msg
            vescDialogLabel.textFormat = richText ? Text.RichText : Text.AutoText
            vescDialog.open()
        }
    }

    Connections {
        target: VescIf

        onPortConnectedChanged: {
            updateConnected()
        }

        onAutoConnectFinished: {
            updateConnected()
        }

        onStatusMessage: {
            statusMessage.text = msg
            statusMessage.color = isGood ? "green" : "red"
        }
    }


    Timer {
        id: bleChecker
        interval: 200
        running: false
        repeat: true

        onTriggered: {
            if(!VescIf.bleDevice().isConnecting() &&
               !VescIf.bleDevice().isConnected()) {
                updateConnected()
                bleChecker.running = false
            }
        }
    }

    // Bluetooth scan button animation
    Timer {
        interval: 500
        running: !scanButton.enabled
        repeat: true

        property int dots: 0
        onTriggered: {
            var text = "Scan"
            for (var i = 0;i < dots;i++) {
                text += "."
            }

            dots++;
            if (dots > 3) {
                dots = 0;
            }

            scanButton.text = text
        }
    }

}
    */
