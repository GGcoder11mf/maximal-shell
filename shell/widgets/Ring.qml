import QtQuick
import QtQuick.Shapes
import qs.services

// Circular gauge with animated sweep.
Item {
    id: root
    property real value: 0           // 0..1
    property real thickness: 6
    property color color: Theme.primary
    property color trackColor: Theme.chip
    property string icon: ""
    property string label: ""
    property int iconSize: Math.round(width * 0.32)
    implicitWidth: 64
    implicitHeight: 64

    property real shown: value
    Behavior on shown { Anim { duration: Theme.slow; easing.type: Theme.expo } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness; radiusY: radiusX
                startAngle: 135; sweepAngle: 270
            }
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness; radiusY: radiusX
                startAngle: 135; sweepAngle: Math.max(0.1, 270 * Math.min(1, root.shown))
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: -2
        Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: root.icon; size: root.iconSize; fill: 1; color: root.color; visible: root.icon !== "" }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.family: Theme.mono
            font.pixelSize: Math.max(9, Math.round(root.width * 0.17))
            font.weight: Font.Bold
            visible: root.label !== ""
        }
    }
}
