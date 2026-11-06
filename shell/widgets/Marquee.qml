import QtQuick
import qs.services

// Text that ping-pong scrolls when it doesn't fit.
Item {
    id: root
    property alias text: t.text
    property alias font: t.font
    property alias color: t.color
    clip: true
    implicitHeight: t.implicitHeight
    readonly property real overflow: Math.max(0, t.implicitWidth - width)

    Txt {
        id: t
        elide: Text.ElideNone
        anchors.verticalCenter: parent.verticalCenter
        SequentialAnimation on x {
            running: root.overflow > 0 && !Theme.calm && root.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 2000 }
            NumberAnimation { to: -root.overflow; duration: root.overflow * 30; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 1500 }
            NumberAnimation { to: 0; duration: root.overflow * 30; easing.type: Easing.InOutSine }
        }
        onTextChanged: x = 0
    }
}
