import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE
import qs.services

// Text filled with the spinning spectrum gradient (+ optional soft glow).
Item {
    id: root
    property alias text: label.text
    property alias font: label.font
    property alias horizontalAlignment: label.horizontalAlignment
    property alias wrapMode: label.wrapMode
    property alias maximumLineCount: label.maximumLineCount
    property alias elide: label.elide
    property alias lineHeight: label.lineHeight
    // set to wrap/elide: the text then lays out within this width
    property real maxWidth: -1
    property bool spinning: !Theme.calm
    property int period: 7000
    property bool glow: true
    implicitWidth: maxWidth > 0 ? Math.min(maxWidth, label.implicitWidth) : label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        width: root.maxWidth > 0 ? root.maxWidth : implicitWidth
        anchors.right: root.horizontalAlignment === Text.AlignRight ? parent.right : undefined
        anchors.left: root.horizontalAlignment === Text.AlignRight ? undefined : parent.left
        anchors.top: parent.top
        visible: false
        color: "white"
        font.family: Theme.font
        font.weight: Font.Bold
        verticalAlignment: Text.AlignVCenter
    }
    Spectrum {
        id: spec
        anchors.fill: parent
        visible: false
        spinning: root.spinning
        period: root.period
    }
    GE.OpacityMask {
        anchors.fill: parent
        source: spec
        maskSource: label
        layer.enabled: root.glow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.primary
            shadowBlur: 0.8 + Viz.pulse * 0.2
            shadowOpacity: Math.min(1, 0.6 + Viz.level * 0.4 + Viz.pulse * 0.4)
            autoPaddingEnabled: true
        }
    }
}
