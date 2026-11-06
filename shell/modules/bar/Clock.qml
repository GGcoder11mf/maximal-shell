import QtQuick
import Quickshell
import qs.services
import qs.widgets

// Gradient clock; hovering reveals seconds + full date. Click: dashboard.
Rectangle {
    id: root
    height: 36
    width: row.implicitWidth + 26
    radius: height / 2
    color: ma.containsMouse ? Theme.glassHi : Theme.chip
    Behavior on width { Anim { duration: Theme.normal; easing.type: Theme.springy } }
    Behavior on color { CAnim {} }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            icon: "schedule"; size: 18; fill: 1; color: Theme.primary
            rotation: clock.date.getSeconds() * 6
            Behavior on rotation { enabled: clock.date.getSeconds() !== 0; Anim { duration: 400; easing.type: Theme.springy } }
        }
        GradientText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 17
            font.weight: Font.Black
            font.family: Theme.font
            glow: false
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: ":" + Qt.formatDateTime(clock.date, "ss")
            font.family: Theme.mono
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Theme.tertiary
            visible: width > 1
            width: ma.containsMouse ? implicitWidth : 0
            elide: Text.ElideNone      // no eliding -> implicitWidth no longer depends on width (binding loop)
            clip: true
            Behavior on width { Anim { easing.type: Theme.springy } }
        }
        Rectangle { width: 1; height: 16; color: Theme.outlineVariant; anchors.verticalCenter: parent.verticalCenter }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: ma.containsMouse ? Qt.formatDateTime(clock.date, "dddd, d MMMM") : Qt.formatDateTime(clock.date, "ddd d MMM")
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Theme.subtext
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Shell.toggle("dashboard")
    }
}
