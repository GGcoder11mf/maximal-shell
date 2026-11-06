import QtQuick
import qs.services

// A little 3D keyboard key.
Item {
    id: root
    property string text: ""
    property color tint: Theme.primary
    implicitWidth: Math.max(26, label.implicitWidth + 14)
    implicitHeight: 26

    Rectangle { anchors.fill: parent; anchors.topMargin: 3; radius: 7; color: Qt.alpha(root.tint, 0.35) }
    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 3
        radius: 7
        color: Theme.surfaceHighest
        border.width: 1
        border.color: Qt.alpha(root.tint, 0.5)
        Txt {
            id: label
            anchors.centerIn: parent
            text: root.text
            font.family: Theme.mono
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Theme.text
        }
    }
}
