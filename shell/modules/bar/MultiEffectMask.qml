import QtQuick
import Qt5Compat.GraphicalEffects as GE

GE.OpacityMask {
    property Item src
    property Item msk
    source: src
    maskSource: msk
}
