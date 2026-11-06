import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Workspace switch indicator: a big number springs in at the centre with one dot per window,
// then fades. Skipped in game mode and while panels (e.g. the overview) are open.
PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "maxi-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    implicitWidth: 320
    implicitHeight: 260
    color: "transparent"
    mask: Region {}
    visible: card.opacity > 0.01

    readonly property int wsId: Hyprland.focusedWorkspace?.id ?? 0
    readonly property int windows: Hyprland.focusedWorkspace?.toplevels?.values?.length ?? 0
    property bool armed: false
    Timer { interval: 2000; running: true; onTriggered: win.armed = true }   // not on startup

    onWsIdChanged: {
        if (!armed || !Shell.wsOsd || Shell.gameMode || Shell.panel !== "" || wsId <= 0) return;
        show.restart();
    }

    Glass {
        id: card
        anchors.centerIn: parent
        width: 220; height: 200
        radius: 40
        fancy: true
        glow: true
        opacity: 0
        scale: 0.6

        GradientText {
            id: num
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            text: win.wsId
            font.pixelSize: 110
            font.weight: Font.Black
            glow: false
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            spacing: 6
            Repeater {
                model: Math.min(8, win.windows)
                Rectangle {
                    id: dot
                    required property int index
                    width: 9; height: 9; radius: 4.5
                    color: Theme.mix(Theme.primary, Theme.magenta, index / 7)
                    scale: 0
                    Component.onCompleted: grow.start()
                    SequentialAnimation {
                        id: grow
                        PauseAnimation { duration: 120 + dot.index * 45 }
                        NumberAnimation { target: dot; property: "scale"; to: 1; duration: Theme.normal; easing.type: Easing.OutBack; easing.overshoot: 3 }
                    }
                }
            }
            Txt { visible: win.windows === 0; text: "empty"; font.pixelSize: 12; color: Theme.subtext }
        }
    }

    SequentialAnimation {
        id: show
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: Theme.fast }
            NumberAnimation { target: card; property: "scale"; from: 0.6; to: 1; duration: Theme.normal; easing.type: Easing.OutBack; easing.overshoot: 2 }
            NumberAnimation { target: num; property: "rotation"; from: -14; to: 0; duration: Theme.slow; easing.type: Easing.OutBack }
        }
        PauseAnimation { duration: 550 }
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 0; duration: Theme.normal }
            NumberAnimation { target: card; property: "scale"; to: 1.1; duration: Theme.normal; easing.type: Easing.InCubic }
        }
    }
}
