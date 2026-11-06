import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

// Full-screen layer used by every panel/overlay. Opens when Shell.panel === name.
// `progress` (0..1) animates on open/close; content should drive its own motion from it.
PanelWindow {
    id: win
    required property string name
    property real dim: 0.35                 // backdrop darkness
    property bool frosted: true             // blur whole screen behind (maxi-overlay) or only opaque parts (maxi-panel)
    property bool grabKeyboard: true
    property string layerName: frosted ? "maxi-overlay" : "maxi-panel"     // Hyprland layer rules key on this
    property int openDuration: Theme.slow
    readonly property bool open: Shell.panel === name
    readonly property alias progress: stage.progress
    default property alias content: stage.data
    signal opened()

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: open || stage.progress > 0.002
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: layerName
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: open && grabKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) { stage.forceActiveFocus(); opened(); }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, win.dim * stage.progress)
        MouseArea { anchors.fill: parent; onClicked: Shell.close() }
    }

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        visible: win.open || progress > 0.002   // hidden -> animators inside stop
        property real progress: win.open ? 1 : 0
        Behavior on progress { NumberAnimation { duration: win.openDuration; easing.type: win.open ? Easing.OutExpo : Easing.OutCubic } }
        Keys.onEscapePressed: Shell.close()
    }
}
