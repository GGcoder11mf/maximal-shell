import QtQuick
import qs.services

// Equaliser bars: the real spectrum (Viz) while audio-reactive mode is on, otherwise decorative bounce.
Row {
    id: root
    property int bars: 5
    property bool playing: Media.playing
    property color color: Theme.primary
    property real barWidth: 3
    spacing: 2

    Repeater {
        model: root.bars
        Rectangle {
            id: bar
            required property int index
            property real fake: 0.2
            readonly property real level: Viz.active && root.visible ? Math.max(0.12, Viz.values[Math.floor(index * Viz.bars / root.bars / 2)] ?? 0) : fake
            width: root.barWidth
            height: Math.max(3, root.height * level)
            anchors.verticalCenter: parent.verticalCenter
            radius: width / 2
            color: Theme.mix(root.color, Theme.tertiary, index / Math.max(1, root.bars - 1))
            Behavior on height { enabled: !Viz.active; Anim { duration: 140; easing.type: Easing.OutQuad } }
            Timer {
                interval: 130 + bar.index * 23
                running: root.playing && !Theme.calm && root.visible && !Viz.active
                repeat: true
                onTriggered: bar.fake = 0.2 + Math.random() * 0.8
                onRunningChanged: if (!running) bar.fake = 0.2
            }
        }
    }
}
