import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12


RoundButton {
    id: control
    icon.width: 40
    icon.height: 40
    implicitWidth: 90
    implicitHeight: 90


    background: Rectangle {
        implicitWidth: control.Material.buttonHeight
        implicitHeight: control.Material.buttonHeight

        radius: control.radius
        color: !control.enabled ? control.Material.buttonDisabledColor
            : control.checked || control.highlighted ? control.Material.highlightedButtonColor : control.Material.buttonColor

        Rectangle {
            width: parent.width
            height: parent.height
            radius: control.radius
            visible: control.hovered || control.visualFocus
            color: control.Material.rippleColor
        }

        Rectangle {
            width: parent.width
            height: parent.height
            radius: control.radius
            visible: control.down
            color: control.Material.rippleColor
        }

        // The layer is disabled when the button color is transparent so that you can do
        // Material.background: "transparent" and get a proper flat button without needing
        // to set Material.elevation as well
        layer.enabled: control.enabled && control.Material.buttonColor.a > 0
        layer.effect: ElevationEffect {
            elevation: control.Material.elevation
        }
    }

}
