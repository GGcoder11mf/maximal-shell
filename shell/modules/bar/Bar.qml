import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Floating glass bar with spinning spectrum border.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData
        WlrLayershell.namespace: "maxi-bar"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; left: true; right: true }
        implicitHeight: 70
        exclusiveZone: Shell.barHidden ? 0 : 60
        color: "transparent"
        // Input region. Must NOT be the bar itself: its entrance animation is a Scale transform,
        // and Region doesn't see transforms — it froze at 60% width, making both ends click-through.
        mask: Region { item: hitArea }
        Item { id: hitArea; x: bar.x; y: bar.y; width: bar.width; height: bar.height }

        readonly property HyprlandMonitor mon: Hyprland.monitorFor(modelData)

        Glass {
            id: bar
            fancy: true
            borderWidth: 1.6 + Viz.pulse * 1.2
            // audio: the border glows with loudness and flashes on beats
            glow: Viz.active
            glowStrength: 0.25 + Viz.level * 0.6 + Viz.pulse * 0.5
            period: 16000
            height: 48
            radius: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            y: Shell.barHidden ? -height - 20 : 10
            opacity: Shell.barHidden ? 0 : 1
            Behavior on y { Anim { duration: Theme.slow; easing.type: Theme.springy } }
            Behavior on opacity { Anim {} }

            // entrance
            transform: Scale { id: enter; origin.x: bar.width / 2; xScale: 0.6 }
            Component.onCompleted: enterAnim.start()
            Anim { id: enterAnim; target: enter; property: "xScale"; from: 0.6; to: 1; duration: Theme.xslow; easing.type: Theme.springy }

            // ── LEFT ───────────────────────────────────
            Row {
                id: left
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                LogoButton { anchors.verticalCenter: parent.verticalCenter }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; monitor: win.mon }
                SubmapBadge { anchors.verticalCenter: parent.verticalCenter }
                ActiveWindow {
                    anchors.verticalCenter: parent.verticalCenter
                    maxWidth: Math.max(0, center.x - left.x - x - 30)
                }
            }

            // ── CENTER ─────────────────────────────────
            Row {
                id: center
                anchors.centerIn: parent
                spacing: 8
                Clock { anchors.verticalCenter: parent.verticalCenter }
                MediaPill { anchors.verticalCenter: parent.verticalCenter }
            }

            // ── RIGHT ──────────────────────────────────
            Row {
                id: right
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Tray { anchors.verticalCenter: parent.verticalCenter; win: win }
                TimerPill { anchors.verticalCenter: parent.verticalCenter }
                ModeBadges { anchors.verticalCenter: parent.verticalCenter }
                Stats { anchors.verticalCenter: parent.verticalCenter }
                StatusIcons { anchors.verticalCenter: parent.verticalCenter }
                PowerButton { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
