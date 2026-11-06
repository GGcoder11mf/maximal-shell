import QtQuick
import qs.services

// Gradient-filled slider with a knob that swells while hovered/dragged.
Item {
    id: root
    property real value: 0          // 0..1 (display)
    property real max: 1
    property string icon: ""
    property bool muted: false
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 40
    readonly property real frac: Math.max(0, Math.min(1, value / max))

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.chip
        clip: true

        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(height, parent.width * root.frac)
            radius: height / 2
            opacity: root.muted ? 0.35 : 1
            Behavior on width { enabled: !ma.pressed; Anim { duration: Theme.normal; easing.type: Theme.expo } }
            Behavior on opacity { Anim {} }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.primary }
                GradientStop { position: 1; color: Theme.tertiary }
            }
            Rectangle {   // knob
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: ma.pressed ? 8 : ma.containsMouse ? 6 : 4
                height: parent.height * (ma.pressed ? 0.7 : 0.5)
                radius: width / 2
                color: Theme.onPrimary
                Behavior on width { Anim { easing.type: Theme.springy } }
                Behavior on height { Anim { easing.type: Theme.springy } }
            }
        }

        Icon {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            size: 20
            fill: 1
            color: root.frac > 0.08 ? Theme.onPrimary : Theme.text
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.iconClicked() }
        }

        Txt {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.value * 100) + "%"
            font.family: Theme.mono
            font.pixelSize: 12
            font.weight: Font.Bold
            color: root.frac > 0.9 ? Theme.onPrimary : Theme.subtext
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.leftMargin: 40
        hoverEnabled: true
        preventStealing: true          // a surrounding Flickable/ListView must never steal the drag
        cursorShape: Qt.PointingHandCursor
        // position on the whole track (the icon area counts as 0) -> 0..max
        function upd(m) { root.moved(Math.max(0, Math.min(1, (m.x + ma.anchors.leftMargin) / root.width)) * root.max); }
        onPressed: m => upd(m)
        onPositionChanged: m => { if (pressed) upd(m); }
        property real acc: 0
        onWheel: w => {                // 5% per notch, smooth wheels/touchpads accumulate
            acc += w.angleDelta.y !== 0 ? w.angleDelta.y : w.pixelDelta.y * 4;
            const steps = acc > 0 ? Math.floor(acc / 120) : Math.ceil(acc / 120);
            if (steps === 0) return;
            acc -= steps * 120;
            root.moved(Math.max(0, Math.min(root.max, Math.round((root.value + steps * 0.05 * root.max) * 20) / 20)));
        }
    }
}
