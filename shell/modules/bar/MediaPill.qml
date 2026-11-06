import QtQuick
import Quickshell
import qs.services
import qs.widgets

// Now-playing pill: art, equaliser, scrolling title; hover reveals controls.
Rectangle {
    id: root
    readonly property bool on: Media.active
    height: 36
    width: on ? row.implicitWidth + 16 : 0
    visible: width > 1
    clip: true
    radius: height / 2
    color: Theme.chip
    Behavior on width { Anim { duration: Theme.slow; easing.type: Theme.springy } }

    // progress underline
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 14
        height: 2; radius: 1
        width: (parent.width - 28) * Media.progress
        color: Theme.tertiary
        Behavior on width { Anim { duration: 900; easing.type: Easing.Linear } }
    }

    Row {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: 28; height: 28; radius: 14
            clip: true
            color: Theme.primaryContainer
            anchors.verticalCenter: parent.verticalCenter
            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(64, 64)
                visible: status === Image.Ready
                RotationAnimator on rotation { from: 0; to: 360; duration: 8000; loops: Animation.Infinite; running: Media.playing && !Theme.calm }
            }
            Icon { anchors.centerIn: parent; icon: "music_note"; size: 16; fill: 1; visible: Media.art === ""; color: Theme.onPrimaryContainer }
        }


        Marquee {
            width: Math.min(220, implicitW)
            readonly property real implicitW: titleMetrics.width + 4
            anchors.verticalCenter: parent.verticalCenter
            text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
            font.pixelSize: 12
            font.weight: Font.Medium
            TextMetrics { id: titleMetrics; font.family: Theme.font; font.pixelSize: 12; text: Media.title + (Media.artist ? "  ·  " + Media.artist : "") }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            width: ma.containsMouse || hov.hovered ? implicitWidth : 0
            clip: true
            Behavior on width { Anim { easing.type: Theme.springy } }
            IconBtn { size: 28; icon: "skip_previous"; onClicked: Media.previous() }
            IconBtn { size: 28; icon: Media.playing ? "pause" : "play_arrow"; active: true; onClicked: Media.toggle() }
            IconBtn { size: 28; icon: "skip_next"; onClicked: Media.next() }
        }
    }

    HoverHandler { id: hov }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        propagateComposedEvents: true
        onClicked: m => m.button === Qt.MiddleButton ? Media.cycle() : Shell.toggle("dashboard")
        onWheel: w => w.angleDelta.y > 0 ? Media.previous() : Media.next()
    }
}
