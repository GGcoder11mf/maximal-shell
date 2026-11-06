import QtQuick
import qs.services

// A slowly rotating multi-colour gradient. Used as a fill for borders, text and accents.
Item {
    id: root
    property bool spinning: !Theme.calm
    property int period: 9000
    property var colors: Theme.spectrum
    clip: true

    Item {
        anchors.fill: parent
        rotation: root.spinning ? Viz.spin * 720 : 0      // audio: music winds the gradient forward
    Rectangle {
        id: grad
        readonly property real d: Math.hypot(root.width, root.height) * 1.2
        width: d; height: d
        anchors.centerIn: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: root.colors[0] }
            GradientStop { position: 0.25; color: root.colors[1] }
            GradientStop { position: 0.5;  color: root.colors[2] }
            GradientStop { position: 0.75; color: root.colors[3] }
            GradientStop { position: 1.0;  color: root.colors[4] }
        }
        // shared 20 fps clock (Theme.spinT only changes while music plays -> no idle repaints).
        // Spectrum is always an invisible mask source, so don't gate on `visible`.
        rotation: root.spinning ? (Theme.spinT % root.period) / root.period * 360 : 0
    }
    }
}
