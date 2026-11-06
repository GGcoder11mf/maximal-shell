import QtQuick
import qs.services

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 14
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    Behavior on color { CAnim {} }
}
