import QtQuick
import qs.services

// Frosted panel: translucent fill, glass sheen, hairline, optional spinning spectrum border.
Rectangle {
    id: root
    property bool fancy: false
    property bool glow: false
    property real glowStrength: 0.7
    property real borderWidth: 2
    property int period: 9000
    default property alias content: inner.data

    color: Theme.glass
    radius: Theme.radius
    border.width: fancy ? 0 : 1
    border.color: Qt.alpha(Theme.outlineVariant, 0.6)
    Behavior on color { CAnim {} }

    // sheen
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.primary, 0.05) }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.fancy
        sourceComponent: GlowBorder { radius: root.radius; thickness: root.borderWidth; glow: root.glow; glowStrength: root.glowStrength; period: root.period }
    }

    Item { id: inner; anchors.fill: parent }
}
