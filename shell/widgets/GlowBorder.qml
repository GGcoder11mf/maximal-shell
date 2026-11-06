import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE
import qs.services

// Spinning spectrum stroke around a rounded rect, with optional outer glow.
Item {
    id: root
    property real radius: Theme.radius
    property real thickness: 2
    property bool glow: false
    property real glowStrength: 0.7
    property bool spinning: !Theme.calm
    property int period: 9000
    anchors.fill: parent

    Spectrum {
        id: spec
        anchors.fill: parent
        visible: false
        spinning: root.spinning
        period: root.period
    }
    Rectangle {
        id: ring
        anchors.fill: parent
        visible: false
        color: "transparent"
        radius: root.radius
        border.width: root.thickness
        border.color: "white"
        antialiasing: true
    }
    GE.OpacityMask {
        anchors.fill: parent
        source: spec
        maskSource: ring
        // audio: every border glows while music plays, and flares on beats
        layer.enabled: root.glow          // music strengthens existing glows; it never adds new layers
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.primary
            shadowBlur: 1.0
            shadowScale: 1 + Viz.pulse * 0.04
            shadowOpacity: Math.min(1, root.glowStrength + Viz.level * 0.5 + Viz.pulse * 0.6)
            autoPaddingEnabled: true
        }
    }
}
