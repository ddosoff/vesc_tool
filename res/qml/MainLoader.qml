/*
    Copyright 2020 Benjamin Vedder	benjamin@vedder.se

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
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtQuick.Window 2.2
import Vedder.vesc.utility 1.0

ApplicationWindow {
    id: mainWindow
    visible: true
    visibility: Window.Windowed
    width: 1920
    height: 1080
    title: qsTr("VESC Custom GUI")

    Material.theme: Utility.isDarkMode() ? "Dark" : "Light"
    Material.accent: Utility.getAppHexColor("lightAccent")

    property string lastFile: ""
    property bool wasFullscreen: false

    onClosing: {
        loader.source = ""
    }

    Loader {
        id: loader
        anchors.fill: parent
    }

    Connections {
        target: QmlUi

        onReloadFile: {
            loader.source = ""
            QmlUi.clearQmlCache()
            loadTimer.start()
            lastFile = fileName
        }

        onToggleFullscreen: {
            wasFullscreen = !wasFullscreen
            if (wasFullscreen) {
                mainWindow.visibility = Window.FullScreen
            } else {
                mainWindow.visibility = Window.Windowed
            }
        }
    }

    Timer {
        id: loadTimer
        repeat: false
        running: false
        interval: 200
        onTriggered: loader.source = lastFile + "?t=" + Date.now()
    }
}
