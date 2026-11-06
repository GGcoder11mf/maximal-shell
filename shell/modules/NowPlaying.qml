import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.widgets

// Desktop "now playing" card (bottom-right of the wallpaper layer):
// album art with a vinyl sliding out of the sleeve, title/artist, live progress,
// and synced lyrics (previous / current / next). Thumps + glows with the music.
Item {
    id: root
    // PERF gate: music values only flow while the desktop is visible (no windows covering it).
    property bool live: true
    readonly property real pz: live ? Viz.pulse : 0
    readonly property real lv: live ? Viz.level : 0
    readonly property real bs: live ? Viz.bass : 0
    readonly property var vals: live ? Viz.values : []
    width: 520
    height: 300
    readonly property bool on: Media.active
    opacity: on ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { Anim { duration: Theme.slow } }
    transform: Translate { x: root.on ? 0 : 60; Behavior on x { Anim { duration: Theme.slow; easing.type: Theme.springy } } }

    // debug render: qs ipc call state snapshot /path.png  -> also writes /path.png.np.png
    Connections {
        target: Shell
        function onSnapshotClock(path: string): void { root.grabToImage(r => r.saveToFile(path + ".np.png")); }
    }

    // ── art + vinyl ───────────────────────────────────────
    Item {
        id: sleeve
        width: 180; height: 180
        anchors.right: parent.right
        anchors.top: parent.top
        scale: 1 + root.pz * 0.03

        // vinyl slides out of the sleeve while playing, spins with the music
        Rectangle {
            id: vinyl
            width: 168; height: 168; radius: 84
            anchors.verticalCenter: parent.verticalCenter
            x: Media.playing ? -74 : -8
            Behavior on x { Anim { duration: Theme.slow * 1.4; easing.type: Theme.springy } }
            color: "#0c0c10"
            border.width: 2
            border.color: Qt.alpha(Theme.primary, 0.35 + root.lv * 0.5)
            RotationAnimator on rotation { from: 0; to: 360; duration: 4000; loops: Animation.Infinite; running: Media.playing && !Theme.calm && root.visible && root.live }
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    anchors.centerIn: parent
                    width: parent.width - 18 - index * 16; height: width; radius: width / 2
                    color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.06)
                }
            }
            ClippingRectangle {
                anchors.centerIn: parent
                width: 56; height: 56; radius: 28
                color: Theme.primaryContainer
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(112, 112) }
            }
            Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: Theme.surface }
        }

        // sleeve = album art
        ClippingRectangle {
            id: art
            anchors.fill: parent
            radius: 18
            color: Theme.primaryContainer
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(360, 360); asynchronous: true }
            Icon { anchors.centerIn: parent; visible: !Media.art; icon: "album"; size: 64; color: Theme.onPrimaryContainer }
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.primary
                shadowBlur: 1.0
                shadowOpacity: 0.35 + root.lv * 0.4 + root.pz * 0.3
                autoPaddingEnabled: true
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Shell.open("stage") }
    }

    // ── text column ───────────────────────────────────────
    ColumnLayout {
        anchors.right: sleeve.left
        anchors.rightMargin: Media.playing ? 96 : 28
        Behavior on anchors.rightMargin { Anim { duration: Theme.slow * 1.4; easing.type: Theme.springy } }
        anchors.top: parent.top
        anchors.topMargin: 6
        width: 300
        spacing: 2

        Txt {
            Layout.alignment: Qt.AlignRight
            text: (Media.playing ? "NOW PLAYING" : "PAUSED") + (Media.player?.identity ? "  ·  " + Media.player.identity.toUpperCase() : "")
            font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2.5
            color: Theme.primary
        }
        GradientText {
            Layout.alignment: Qt.AlignRight
            Layout.maximumWidth: 300
            text: Music.title || Media.title
            font.pixelSize: 26; font.weight: Font.Black
            horizontalAlignment: Text.AlignRight
            maxWidth: 300; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
            glow: false
        }
        Txt {
            Layout.alignment: Qt.AlignRight
            Layout.maximumWidth: 300
            text: Music.artist || Media.artist
            font.pixelSize: 14; font.weight: Font.Medium
            color: Qt.alpha(Theme.text, 0.85)
            horizontalAlignment: Text.AlignRight
        }
        // progress
        Item {
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 220
            Layout.preferredHeight: 14
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Qt.alpha(Theme.text, 0.15) }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * Media.progress; height: 4 + root.pz * 2; radius: 3
                Behavior on width { Anim { duration: 900; easing.type: Easing.Linear } }
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.magenta } }
            }
        }
        Txt {
            Layout.alignment: Qt.AlignRight
            text: Media.fmt(Media.position) + " / " + Media.fmt(Media.length)
            font.family: Theme.mono; font.pixelSize: 10; color: Theme.subtext
        }

        // synced lyrics
        Item { Layout.preferredHeight: 6 }
        Lyric { Layout.alignment: Qt.AlignRight; text: Music.prevLine; size: 12; dim: 0.35 }
        Lyric { Layout.alignment: Qt.AlignRight; text: Music.line; size: 17; dim: 1; current: true }
        Lyric { Layout.alignment: Qt.AlignRight; text: Music.nextLine; size: 12; dim: 0.45 }
    }

    component Lyric: Txt {
        id: ly
        property real size: 14
        property real dim: 1
        property bool current: false
        visible: Music.hasLyrics
        Layout.maximumWidth: 320
        horizontalAlignment: Text.AlignRight
        font.pixelSize: size
        font.weight: current ? Font.Bold : Font.Normal
        color: current ? Theme.mix(Theme.text, Theme.primary, 0.35 + root.pz * 0.4) : Qt.alpha(Theme.text, dim)
        opacity: 1
        // each new line fades/slides in
        onTextChanged: if (current) { enter.restart(); }
        SequentialAnimation {
            id: enter
            NumberAnimation { target: ly; property: "opacity"; from: 0; to: 1; duration: Theme.normal }
        }
    }
}
