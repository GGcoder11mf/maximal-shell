import QtQuick
import qs.services
import qs.widgets

// Spinning spectrum orb → dashboard (right click: launcher)
Item {
    id: root
    width: 36; height: 36

    Spectrum {
        id: orb
        anchors.fill: parent
        visible: false
        layer.enabled: true
        period: ma.containsMouse ? 1600 : 6000
    }
    Rectangle { id: circ; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }

    Item {
        anchors.fill: parent
        scale: ma.pressed ? 0.85 : ma.containsMouse ? 1.12 : 1
        transform: Scale { origin.x: 18; origin.y: 18; xScale: 1 + Viz.pulse * 0.18; yScale: 1 + Viz.pulse * 0.18 }   // beat, live
        Behavior on scale { Anim { duration: Theme.normal; easing.type: Theme.springy } }
        rotation: Shell.panel === "dashboard" ? 180 : 0
        Behavior on rotation { Anim { duration: Theme.slow; easing.type: Theme.springy } }

        MultiEffectMask { anchors.fill: parent; src: orb; msk: circ }
        Icon {
            anchors.centerIn: parent
            icon: "blur_on"
            size: 22
            fill: 1
            weight: 700
            color: Theme.onPrimary
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => Shell.toggle(m.button === Qt.RightButton ? "launcher" : "dashboard")
    }
}
