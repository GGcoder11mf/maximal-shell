import QtQuick
import qs.services

// Material Symbols Rounded via ligatures; `fill` animates the FILL axis.
Text {
    id: root
    property string icon: ""
    property real fill: 0
    property int weight: 500
    property int size: 20

    text: icon
    color: Theme.text
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": root.fill, "wght": root.weight, "opsz": Math.min(48, Math.max(20, root.size)), "GRAD": 0 })
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on fill { Anim { duration: Theme.normal } }
    Behavior on color { CAnim {} }
}
