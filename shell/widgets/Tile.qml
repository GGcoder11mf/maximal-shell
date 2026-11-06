import QtQuick
import qs.services

// Quick-settings toggle tile.
Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    signal clicked()
    signal rightClicked()

    implicitHeight: 64
    radius: Theme.radius
    color: active ? "transparent" : (ma.containsMouse ? Theme.glassHi : Theme.chip)
    scale: ma.pressed ? 0.94 : 1
    Behavior on scale { Anim { easing.type: Theme.springy } }
    Behavior on color { CAnim {} }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        opacity: root.active ? 1 : 0
        Behavior on opacity { Anim {} }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.primary }
            GradientStop { position: 1; color: Theme.tertiary }
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 12
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 36; radius: 12
            color: root.active ? Qt.alpha(Theme.onPrimary, 0.16) : Theme.chip
            Behavior on color { CAnim {} }
            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 20
                fill: root.active ? 1 : 0
                color: root.active ? Theme.onPrimary : Theme.text
                rotation: root.active ? 0 : -12
                Behavior on rotation { Anim { duration: Theme.slow; easing.type: Theme.springy } }
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 60
            Txt { width: parent.width; text: root.label; font.pixelSize: 13; font.weight: Font.DemiBold; color: root.active ? Theme.onPrimary : Theme.text }
            Txt { width: parent.width; text: root.sublabel; font.pixelSize: 11; color: root.active ? Qt.alpha(Theme.onPrimary, 0.8) : Theme.subtext; visible: text !== "" }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
