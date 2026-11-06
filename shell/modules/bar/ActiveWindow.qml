import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.widgets

// App icon + title of the focused window, with a slide/fade on change.
Item {
    id: root
    property real maxWidth: 400
    // Wayland's toplevel manager knows the active window immediately and stays live;
    // Hyprland.activeToplevel is only filled in by the *next* focus event (empty after a restart).
    readonly property var wl: ToplevelManager.activeToplevel
    readonly property var toplevel: Hyprland.activeToplevel
    readonly property string cls: wl?.appId || Apps.classOf(toplevel)
    readonly property string title: wl?.title || toplevel?.title || ""
    readonly property bool has: title !== "" && (Hyprland.focusedWorkspace?.toplevels?.values?.length ?? 0) > 0

    width: Math.min(maxWidth, content.implicitWidth)
    height: 36
    clip: true
    visible: maxWidth > 60
    Behavior on width { Anim { duration: Theme.normal; easing.type: Theme.smooth } }

    Row {
        id: content
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.has ? 1 : 0.6

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 20
            visible: root.has
            source: Apps.icon(root.cls, "application-x-executable")
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt {
                id: clsTxt
                text: root.has ? (Apps.name(root.cls) || root.title) : "Desktop"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.primary
                width: Math.min(implicitWidth, root.maxWidth - 30)
            }
            Txt {
                id: titleTxt
                text: root.has ? root.title : Hyprland.focusedWorkspace ? "Workspace " + Hyprland.focusedWorkspace.id : ""
                font.pixelSize: 12
                color: Theme.subtext
                width: Math.min(implicitWidth, root.maxWidth - 30)
            }
        }
    }

    onTitleChanged: bump.restart()
    SequentialAnimation {
        id: bump
        Anim { target: content; property: "x"; to: 8; duration: 0 }
        Anim { target: content; property: "x"; to: 0; duration: Theme.normal; easing.type: Theme.springy }
    }
}
