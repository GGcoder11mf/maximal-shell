import QtQuick
import qs.services
import qs.widgets

// Countdown in the bar: progress ring + time. Click = pause/resume, right-click = cancel.
// Grows in when a timer starts; when it ends, the ring bursts outward and the pill collapses.
Rectangle {
    id: root
    readonly property bool on: Timers.active
    height: 30
    width: on ? row.implicitWidth + 18 : 0
    visible: width > 1 || burst.running
    clip: !burst.running
    radius: height / 2
    color: Timers.paused ? Theme.chip : Qt.alpha(Theme.primary, 0.18)
    border.width: 1
    border.color: Qt.alpha(Theme.primary, Timers.paused ? 0.3 : 0.6)
    Behavior on width { Anim { duration: Theme.slow; easing.type: Theme.springy } }
    Behavior on color { CAnim {} }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Ring {
            width: 20; height: 20; thickness: 3
            value: Timers.progress
            color: Timers.remaining < 10 ? Theme.red : Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Timers.fmt(Timers.remaining)
            font.family: Theme.mono; font.pixelSize: 12; font.weight: Font.Black
            color: Timers.remaining < 10 ? Theme.red : Theme.text
            // last 10 s: each second pops
            scale: 1
            onTextChanged: if (Timers.remaining < 10 && Timers.active) pop.restart()
            SequentialAnimation on scale { id: pop; running: false
                NumberAnimation { to: 1.25; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { to: 1.0; duration: 260; easing.type: Easing.OutBack }
            }
        }
        Icon { visible: Timers.paused; icon: "pause"; size: 14; fill: 1; color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter }
    }

    // finish burst: an expanding ring
    Rectangle {
        id: ringFx
        anchors.centerIn: parent
        width: 30; height: 30; radius: 15
        color: "transparent"
        border.width: 3
        border.color: Theme.primary
        opacity: 0
        ParallelAnimation {
            id: burst
            NumberAnimation { target: ringFx; property: "scale"; from: 1; to: 5; duration: 900; easing.type: Easing.OutCubic }
            NumberAnimation { target: ringFx; property: "opacity"; from: 1; to: 0; duration: 900 }
        }
    }
    Connections { target: Timers; function onFinished() { burst.restart(); } }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.RightButton ? Timers.cancel() : Timers.togglePause()
    }
}
