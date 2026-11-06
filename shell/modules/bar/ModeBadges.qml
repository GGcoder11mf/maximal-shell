import QtQuick
import qs.services
import qs.widgets

// Little animated badges for active modes: REC, caffeine, DND, game mode, screen effect.
Row {
    id: root
    spacing: 4

    component Badge: Rectangle {
        id: b
        property bool on: false
        property string icon: ""
        property color tint: Theme.primary
        property string label: ""
        height: 30
        width: on ? inner.implicitWidth + 16 : 0
        visible: width > 1
        clip: true
        radius: height / 2
        color: Qt.alpha(tint, 0.2)
        border.width: 1
        border.color: Qt.alpha(tint, 0.6)
        Behavior on width { Anim { duration: Theme.normal; easing.type: Theme.springy } }
        Row {
            id: inner
            anchors.centerIn: parent
            spacing: 4
            Icon { icon: b.icon; size: 16; fill: 1; color: b.tint; anchors.verticalCenter: parent.verticalCenter }
            Txt { text: b.label; visible: text !== ""; font.pixelSize: 11; font.weight: Font.Black; color: b.tint }
        }
    }

    Badge {
        id: rec
        on: Shell.recording; icon: "radio_button_checked"; tint: Theme.red; label: "REC"
        SequentialAnimation on opacity {
            running: rec.on; loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
        }
    }
    Badge { on: Shell.caffeine; icon: "coffee"; tint: Theme.orange }
    Badge { on: Shell.dnd; icon: "do_not_disturb_on"; tint: Theme.red }
    Badge { on: Shell.gameMode; icon: "sports_esports"; tint: Theme.green; label: "GAME" }
    Badge { on: Shell.shader !== ""; icon: Shell.shader === "nightlight" ? "nightlight" : "auto_awesome"; tint: Theme.yellow }
}
