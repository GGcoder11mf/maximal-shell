import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.widgets

// While a Hyprland submap is active, show its keys.
PanelWindow {
    id: win
    readonly property bool on: Shell.submap !== ""
    property string name: ""
    onOnChanged: if (on) { name = Shell.submap; Binds.refresh(); }
    readonly property var binds: (Binds.submaps[name] ?? []).filter(b => b.desc !== "Exit")

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "maxi-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors.bottom: true
    implicitWidth: 760
    implicitHeight: card.implicitHeight + 60
    color: "transparent"
    mask: Region {}
    visible: on || card.opacity > 0.01

    Glass {
        id: card
        fancy: true
        glow: true
        radius: 26
        width: parent.width
        implicitHeight: content.implicitHeight + 36
        anchors.horizontalCenter: parent.horizontalCenter
        y: win.on ? 10 : 80
        opacity: win.on ? 1 : 0
        Behavior on y { Anim { duration: Theme.slow; easing.type: Theme.springy } }
        Behavior on opacity { Anim {} }

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 14
            Row {
                spacing: 12
                Icon { icon: "keyboard"; size: 26; fill: 1; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                GradientText { text: win.name.toUpperCase() + " MODE"; font.pixelSize: 22; font.weight: Font.Black; font.letterSpacing: 4 }
                Txt { text: "Esc / Enter to exit"; color: Theme.subtext; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            Flow {
                width: parent.width
                spacing: 10
                Repeater {
                    model: win.binds
                    Row {
                        required property var modelData
                        spacing: 6
                        Repeater { model: parent.modelData.keys; Keycap { required property string modelData; text: modelData } }
                        Txt { text: parent.modelData.desc; font.pixelSize: 12; color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter; rightPadding: 10 }
                    }
                }
            }
        }
    }
}
