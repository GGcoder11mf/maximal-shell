import QtQuick
import qs.services

// Live spectrum from Viz. `mirrored`: bass in the centre, spreading outwards (symmetric skyline).
// `fromCenter`: bars grow up and down from the vertical middle instead of from the bottom.
Item {
    id: root
    property bool mirrored: true
    property bool fromCenter: false
    property real gap: 3
    property real minBar: 2
    property real radius: 3
    property real gain: 1.0
    property int step: 1                  // use every Nth band (fewer items = cheaper)
    readonly property var values: Viz.values
    readonly property int n: Math.floor(Viz.bars / step)
    readonly property int count: mirrored ? n * 2 : n

    Row {
        anchors.bottom: root.fromCenter ? undefined : parent.bottom
        anchors.verticalCenter: root.fromCenter ? parent.verticalCenter : undefined
        height: parent.height
        spacing: root.gap

        Repeater {
            model: root.count
            Item {
                id: slot
                required property int index
                readonly property int vi: root.mirrored ? (index < root.n ? root.n - 1 - index : index - root.n) : index
                readonly property real v: Math.min(1, (root.values[vi * root.step] ?? 0) * root.gain)
                width: Math.max(1, (root.width - root.gap * (root.count - 1)) / root.count)
                height: parent.height

                Rectangle {
                    width: parent.width
                    height: Math.max(root.minBar, slot.v * parent.height)
                    anchors.bottom: root.fromCenter ? undefined : parent.bottom
                    anchors.verticalCenter: root.fromCenter ? parent.verticalCenter : undefined
                    radius: Math.min(root.radius, width / 2)
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.mix(Theme.tertiary, Theme.magenta, slot.vi / root.n) }
                        GradientStop { position: 1; color: Qt.alpha(Theme.primary, 0.35) }
                    }
                }
            }
        }
    }
}
