import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Mode-change toasts (bottom centre): layout, gaps, game mode, wallpaper…
PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "maxi-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors.bottom: true
    implicitWidth: 520
    implicitHeight: 260
    color: "transparent"
    mask: Region {}
    visible: Toaster.items.length > 0 || rm.running

    ListView {
        id: list
        anchors.fill: parent
        anchors.bottomMargin: 40
        verticalLayoutDirection: ListView.BottomToTop
        spacing: 10
        interactive: false
        model: ScriptModel { values: Toaster.items; objectProp: "id" }

        delegate: Item {
            id: d
            required property var modelData
            width: list.width
            height: 60
            Glass {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 56
                width: row.implicitWidth + 36
                radius: 28
                fancy: true
                glow: true
                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 14
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.primary }
                            GradientStop { position: 1; color: Theme.tertiary }
                        }
                        Icon {
                            id: ic
                            anchors.centerIn: parent
                            icon: d.modelData.icon
                            size: 20; fill: 1; color: Theme.onPrimary
                            RotationAnimator on rotation { from: -180; to: 0; duration: Theme.slow * 1.5; easing.type: Easing.OutBack }
                        }
                    }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: d.modelData.title; font.pixelSize: 14; font.weight: Font.Black }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: d.modelData.body; font.pixelSize: 13; color: Theme.subtext; visible: text !== "" }
                }
            }
        }
        add: Transition {
            NumberAnimation { property: "y"; from: list.height; duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: Theme.slow; easing.type: Easing.OutBack }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
        }
        remove: Transition {
            id: rm
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.normal }
            NumberAnimation { property: "scale"; to: 0.7; duration: Theme.normal; easing.type: Easing.InBack }
        }
        displaced: Transition { NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Easing.OutBack } }
    }
}
