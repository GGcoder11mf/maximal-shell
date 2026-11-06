import QtQuick
import qs.services
import qs.widgets

// Shows the active Hyprland submap (resize / move / launch …)
Rectangle {
    id: root
    readonly property bool on: Shell.submap !== ""
    property string last: ""
    onOnChanged: if (on) last = Shell.submap
    height: 30
    width: on ? row.implicitWidth + 22 : 0
    visible: width > 1
    clip: true
    radius: height / 2
    color: Theme.errorContainer
    Behavior on width { Anim { duration: Theme.normal; easing.type: Theme.springy } }

    SequentialAnimation on opacity {
        running: root.on; loops: Animation.Infinite
        NumberAnimation { to: 0.7; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon { icon: "keyboard_command_key"; size: 16; fill: 1; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: root.last.toUpperCase(); font.pixelSize: 12; font.weight: Font.Black; font.letterSpacing: 2 }
    }
}
