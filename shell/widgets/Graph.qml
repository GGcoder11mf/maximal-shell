import QtQuick
import QtQuick.Shapes
import qs.services

// Area sparkline with a gradient fill.
Item {
    id: root
    property var values: []          // numbers
    property real max: 1
    property color color: Theme.primary
    property bool autoScale: false

    readonly property real peak: autoScale ? Math.max(1, ...values) : max
    readonly property var pts: values.map((v, i) => Qt.point(
        values.length > 1 ? i / (values.length - 1) * width : 0,
        height - Math.min(1, v / peak) * (height - 2) - 1))

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: root.height
                GradientStop { position: 0; color: Qt.alpha(root.color, 0.45) }
                GradientStop { position: 1; color: Qt.alpha(root.color, 0.0) }
            }
            startX: 0; startY: root.height
            PathPolyline { path: root.pts }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
        }
        ShapePath {
            strokeWidth: 2
            strokeColor: root.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: root.pts }
        }
    }
}
