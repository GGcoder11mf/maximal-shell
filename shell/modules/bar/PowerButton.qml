import QtQuick
import qs.services
import qs.widgets

Item {
    width: 36; height: 36
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        scale: ma.pressed ? 0.85 : ma.containsMouse ? 1.1 : 1
        Behavior on scale { Anim { easing.type: Theme.springy } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.red }
            GradientStop { position: 1; color: Theme.magenta }
        }
        Icon {
            anchors.centerIn: parent
            icon: "power_settings_new"; size: 19; fill: 1; weight: 700
            color: "#1a0010"
            rotation: ma.containsMouse ? 90 : 0
            Behavior on rotation { Anim { duration: Theme.slow; easing.type: Theme.springy } }
        }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Shell.toggle("power") }
}
