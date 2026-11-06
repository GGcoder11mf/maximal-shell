import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Volume / mic OSD: a glowing vertical gauge that slides in from the right edge.
PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "maxi-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors.right: true
    implicitWidth: 110
    implicitHeight: 340
    color: "transparent"
    mask: Region {}
    visible: card.shown || slideX.running || card.x < width

    property string mode: "volume"   // volume | mic
    property bool armed: false
    Timer { interval: 1500; running: true; onTriggered: win.armed = true }

    function show(m) {
        if (!armed) return;
        mode = m;
        card.shown = true;
        hide.restart();
    }
    Timer { id: hide; interval: 1600; onTriggered: card.shown = false }

    Connections {
        target: Audio
        function onVolumeChanged() { win.show("volume"); }
        function onMutedChanged() { win.show("volume"); }
        function onMicMutedChanged() { win.show("mic"); }
    }

    readonly property real value: mode === "mic" ? Audio.micVolume : Audio.volume
    readonly property bool muted: mode === "mic" ? Audio.micMuted : Audio.muted

    Glass {
        id: card
        property bool shown: false
        fancy: true
        glow: true
        width: 70
        height: 300
        radius: 35
        anchors.verticalCenter: parent.verticalCenter
        x: shown ? win.width - width - 18 : win.width + 10
        Behavior on x { NumberAnimation { id: slideX; duration: Theme.slow; easing.type: card.shown ? Easing.OutBack : Easing.InCubic; easing.overshoot: 2 } }
        scale: shown ? 1 : 0.8
        Behavior on scale { Anim { duration: Theme.slow; easing.type: Theme.springy } }

        Txt {
            id: pct
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            text: win.muted ? "—" : Math.round(win.value * 100)
            font.family: Theme.mono
            font.pixelSize: 16
            font.weight: Font.Black
            color: win.value > 1 ? Theme.red : Theme.text
        }

        Rectangle {
            id: track
            anchors.top: pct.bottom
            anchors.topMargin: 10
            anchors.bottom: icon.top
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: 22
            radius: 11
            color: Theme.chip
            clip: true

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                radius: 11
                height: Math.max(width, parent.height * Math.min(1, win.value))
                opacity: win.muted ? 0.3 : 1
                Behavior on height { Anim { duration: Theme.normal; easing.type: Theme.springy } }
                Behavior on opacity { Anim {} }
                gradient: Gradient {
                    GradientStop { position: 0; color: win.value > 1 ? Theme.red : Theme.tertiary }
                    GradientStop { position: 0.5; color: Theme.magenta }
                    GradientStop { position: 1; color: Theme.primary }
                }
                // shimmer
                Rectangle {
                    width: parent.width; height: 40
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.35) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                    NumberAnimation on y { from: track.height; to: -40; duration: 1400; loops: Animation.Infinite; running: card.shown && !Theme.calm }
                }
            }
        }

        Icon {
            id: icon
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            icon: win.mode === "mic" ? Audio.micIcon : Audio.icon
            size: 26
            fill: 1
            color: win.muted ? Theme.red : Theme.primary
            scale: card.shown ? 1 : 0.4
            Behavior on scale { Anim { duration: Theme.slow; easing.type: Theme.springy } }
        }
    }
}
