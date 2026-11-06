import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.services
import qs.widgets

// "Now playing" card that drops in under the bar when the track changes.
PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "maxi-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    implicitWidth: 560
    implicitHeight: 150
    color: "transparent"
    mask: Region {}
    visible: card.shown || card.y > -card.height

    // don't pop over the stage / dashboard (they already show the track)
    Connections {
        target: Music
        function onTrackChanged() {
            if (Shell.panel === "stage" || Shell.panel === "dashboard" || Shell.gameMode) return;
            card.title = Music.title || Media.title;
            card.artist = Music.artist || Media.artist;
            card.art = Media.art;
            card.shown = true;
            hide.restart();
        }
    }
    Timer { id: hide; interval: 3800; onTriggered: card.shown = false }

    Glass {
        id: card
        property bool shown: false
        property string title
        property string artist
        property string art
        width: Math.min(win.width, row.implicitWidth + 30)
        height: 84
        radius: 26
        fancy: true
        glow: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: shown ? 66 : -height - 10
        Behavior on y { Anim { duration: Theme.slow; easing.type: card.shown ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.6 } }
        scale: shown ? 1 : 0.85
        Behavior on scale { Anim { duration: Theme.slow; easing.type: Theme.springy } }

        RowLayout {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            spacing: 14
            ClippingRectangle {
                Layout.preferredWidth: 60; Layout.preferredHeight: 60
                radius: 16
                color: Theme.primaryContainer
                Image { anchors.fill: parent; source: card.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(120, 120) }
                Icon { anchors.centerIn: parent; visible: !card.art; icon: "music_note"; size: 28; color: Theme.onPrimaryContainer }
                RotationAnimator on rotation { running: card.shown && !Theme.calm; from: -12; to: 0; duration: Theme.slow * 1.4; easing.type: Easing.OutBack }
            }
            ColumnLayout {
                spacing: 1
                Txt { text: "NOW PLAYING"; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2.5; color: Theme.primary }
                Txt { text: card.title; font.pixelSize: 16; font.weight: Font.Black; Layout.maximumWidth: 400 }
                Txt { text: card.artist; font.pixelSize: 12; color: Theme.subtext; Layout.maximumWidth: 400 }
            }
            Visualizer { Layout.preferredHeight: 28; bars: 6; barWidth: 3; Layout.rightMargin: 6; visible: card.shown }
        }
    }
}
