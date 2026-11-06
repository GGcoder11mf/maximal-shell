import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Popup stack (top-right). Cards fly in from the right, others glide out of the way.
PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "maxi-notifs"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    anchors { top: true; right: true; bottom: true }
    implicitWidth: 430
    color: "transparent"
    mask: Region { item: list.contentItem }
    visible: Notifs.popups.length > 0 || removeAnim.running

    ListView {
        id: list
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.rightMargin: 12
        anchors.leftMargin: 20
        spacing: 10
        interactive: false
        model: ScriptModel { values: Notifs.popups.slice(0, 5) }

        delegate: NotifCard {
            required property QtObject modelData
            entry: modelData
            width: list.width
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: 460; to: 0; duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: Theme.slow; easing.type: Easing.OutBack }
            }
        }
        remove: Transition {
            id: removeAnim
            ParallelAnimation {
                NumberAnimation { property: "x"; to: 460; duration: Theme.normal; easing.type: Easing.InCubic }
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.normal }
            }
        }
        displaced: Transition {
            NumberAnimation { properties: "y"; duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }
    }
}
