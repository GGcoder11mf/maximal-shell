import QtQuick
import qs.services

// Round icon button: hover highlight, squish on press, ripple on click.
Item {
    id: root
    property string icon: ""
    property int size: 34
    property int iconSize: Math.round(size * 0.56)
    property bool active: false
    property color activeColor: Theme.primary
    property color iconColor: active ? Theme.onPrimary : Theme.text
    property real radius: size / 2
    property alias hovered: ma.containsMouse
    readonly property alias pressed: ma.pressed
    signal clicked()
    signal rightClicked()
    signal scrolled(int delta)

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        clip: true
        color: root.active ? root.activeColor : ma.containsMouse ? Theme.chip : "transparent"
        scale: ma.pressed ? 0.86 : ma.containsMouse ? 1.06 : 1
        Behavior on color { CAnim {} }
        Behavior on scale { Anim { duration: Theme.normal; easing.type: Theme.springy } }

        Rectangle {
            id: ripple
            property real cx: 0
            property real cy: 0
            x: cx - width / 2; y: cy - height / 2
            width: 0; height: width; radius: width / 2
            color: Qt.alpha(root.active ? Theme.onPrimary : Theme.primary, 0.35)
            opacity: 0
            ParallelAnimation {
                id: rippleAnim
                Anim { target: ripple; property: "width"; from: 0; to: root.size * 2.6; duration: Theme.slow; easing.type: Easing.OutQuad }
                Anim { target: ripple; property: "opacity"; from: 1; to: 0; duration: Theme.slow }
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        color: root.iconColor
        fill: root.active || ma.containsMouse ? 1 : 0
        scale: bg.scale
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            ripple.cx = m.x; ripple.cy = m.y; rippleAnim.restart();
            if (m.button === Qt.RightButton) root.rightClicked(); else root.clicked();
        }
        onWheel: w => root.scrolled(w.angleDelta.y)
    }
}
