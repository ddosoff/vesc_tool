import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.0

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

        Label {
            text: qsTr("Find Skypuff")

            Layout.fillWidth: true
            Layout.topMargin: bBluetooth.size / 3
            Layout.bottomMargin: bBluetooth.size / 4

            horizontalAlignment: Text.AlignHCenter

            font.pixelSize: bBluetooth.size / 3
            font.bold: true
        }

        // Methods buttons
        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            BigRoundButton {
                id: bBluetooth
                icon.source: "qrc:/res/icons/bluetooth.svg"
                Material.foreground: Material.Blue
                onClicked: {
                    if(!busy) {
                        listModel.clearByType('bt')
                        mBle.startScan()
                        busy = true;
                    }
                }
                Component.onCompleted: clicked()
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
            Layout.topMargin: 20
            ScrollBar.vertical: ScrollBar {}
            clip: true
            //highlightFollowsCurrentItem: false
            //focus: true

            delegate: Item {
                id: delegateItem
                width: listView.width
                clip: true
                /*Rectangle {
                    anchors.fill: parent
                    color: "#aaddaa"
                    visible: isVesc
                }*/

                Image {
                    id: connectionType
                    anchors {
                        left: parent.left
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    smooth: true

                    source: type === "bt" ? "qrc:/res/icons/bluetooth.svg" :
                            type === "usb" ? "qrc:/res/icons/usb.svg" :
                            "qrc:/res/icons/wifi.svg"

                    sourceSize.width: type === "bt" ? bBluetooth.icon.width :
                                      type === "usb" ? bUsb.icon.width :
                                      bWifi.icon.width
                    sourceSize.height: type === "bt" ? bBluetooth.icon.height :
                                                       type === "usb" ? bUsb.icon.height :
                                                       bWifi.icon.height

                    visible: false

                }
                ColorOverlay {
                    anchors.fill: connectionType
                    source: connectionType
                    color: Material.color(Material.Blue)

                    RotationAnimation on rotation {
                        id: connectionTypeRotator
                        from: 0;
                        to: 360;
                        duration: 1100
                        running: false
                    }
                }

                Text {
                    anchors {
                        left: connectionType.right
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter;
                    }
                    id: tName
                    text: name
                    font.pixelSize: 15
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: connectionTypeRotator.running = true
                }

                ListView.onAdd: SequentialAnimation {
                    PropertyAction { target: delegateItem; property: "height"; value: 0 }
                    NumberAnimation { target: delegateItem; property: "height"; to: tName.contentHeight + 20; duration: 700; easing.type: Easing.InOutQuad }
                }
            }

            model: ListModel {
                id: listModel

                function find(type, addr) {
                    for(var i = 0; i < count; i++) {
                        var e = get(i);
                        if(e.addr === addr && e.type === type)
                            return i
                    }
                    return -1
                }

                function clearByType(t) {
                    for(var i = 0; i < count; i++) {
                        var e = get(i);
                        if(e.type === t) {
                            remove(i)
                            i--
                        }
                    }
                }
            }

        }
    }

    /*footer: Label {
        verticalAlignment: Text.AlignVCenter;
        x: 5;
        height: contentHeight + 8
        text: qsTr("Not connected")
    }*/

    // Bluetooth
    Connections {
        target: mBle


        onScanDone: {
            if (done) {
                bBluetooth.busy = false
            }

            for (var addr in devs) {
                if(listModel.find("bt", addr) !== -1) {
                    // TODO: replace
                    continue
                }

                var name = devs[addr]
                var name2 = name + " [" + addr + "]"
                var setName = VescIf.getBleName(addr)
                if (setName.length > 0) {
                    setName += " [" + addr + "]"
                    listModel.insert(0, {type: "bt", name: setName, addr: addr, isVesc: true})
                } else if (name.indexOf("VESC") !== -1) {
                    listModel.insert(0, {type: "bt", name: name2, addr: addr, isVesc: true})
                } else {
                    listModel.append({type: "bt", name: name2, addr: addr, isVesc: false})
                }
            }
        }

        onBleError: {
            VescIf.emitMessageDialog("BLE Error", info, false, false)
        }
    }

}

        /*

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
