import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.widgets

// MUSIC STAGE — full-screen now-playing scene.
// Opens with Super+F11 / >stage / clicking the desktop album art, and by itself when you're idle
// while music plays (closes again on input). Esc / click the backdrop to leave.
Overlay {
    id: root
    name: "stage"
    dim: 0.0
    openDuration: Theme.xslow
    layerName: "maxi-stage"    // fully opaque: no Hyprland blur behind it (see rules.lua)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ── backdrop: blurred cover, breathing with the bass ──
    Item {
        anchors.fill: parent
        opacity: root.progress
        Rectangle { anchors.fill: parent; color: Theme.surface }
        Image {
            id: bgArt
            anchors.centerIn: parent
            width: parent.width * 1.25; height: parent.height * 1.25
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(320, 320)
            visible: false
        }
        MultiEffect {
            anchors.fill: bgArt
            source: bgArt
            visible: Media.art !== ""
            // static effect params -> the blur is rendered once per cover, not per audio frame;
            // the bass "breathing" is a plain scale transform (cheap)
            blurEnabled: true; blur: 1; blurMax: 64
            saturation: 0.35
            brightness: -0.22
            scale: 1 + Viz.bass * 0.04 + Viz.pulse * 0.02
            opacity: 0.85
        }
        Rectangle {    // vignette
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.surface, 0.35) }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha(Theme.surface, 0.75) }
            }
        }
    }

    // swallow clicks on content; backdrop click (Overlay) closes
    Item {
        anchors.fill: parent
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress

        // top-left: time + close hint
        ColumnLayout {
            x: 70; y: 56
            spacing: 0
            GradientText { text: Qt.formatDateTime(clock.date, "HH:mm"); font.pixelSize: 54; font.weight: Font.Black; glow: false }
            Txt { text: Qt.formatDateTime(clock.date, "dddd · d MMMM").toUpperCase(); font.pixelSize: 12; font.letterSpacing: 3; color: Theme.subtext }
        }
        Txt {
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 60
            text: "esc  ·  click anywhere to leave"
            font.family: Theme.mono; font.pixelSize: 11; color: Qt.alpha(Theme.subtext, 0.7)
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 90

            // ── art + radial spectrum ──────────────────────
            Item {
                id: disc
                Layout.preferredWidth: 560
                Layout.preferredHeight: 560
                readonly property real artSize: 380
                scale: 1 + Viz.pulse * 0.025

                Repeater {
                    model: root.open ? 96 : 0
                    Rectangle {
                        id: ray
                        required property int index
                        readonly property int band: index < 48 ? index : 95 - index
                        readonly property real v: Viz.values[Math.floor(band * Viz.bars / 48)] ?? 0
                        width: 4
                        height: 6 + v * 80
                        radius: 2
                        x: disc.width / 2 - width / 2
                        y: disc.height / 2 - disc.artSize / 2 - 18 - height
                        color: Theme.mix(Theme.primary, Theme.magenta, Math.min(1, v * 1.3))
                        opacity: 0.55 + v * 0.45
                        transform: Rotation { origin.x: ray.width / 2; origin.y: ray.height + 18 + disc.artSize / 2; angle: ray.index * 360 / 96 }
                    }
                }
                ClippingRectangle {
                    anchors.centerIn: parent
                    width: disc.artSize; height: width
                    radius: 34
                    color: Theme.primaryContainer
                    Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(760, 760); asynchronous: true }
                    Icon { anchors.centerIn: parent; visible: !Media.art; icon: "album"; size: 120; color: Theme.onPrimaryContainer }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true; shadowColor: Theme.primary; shadowBlur: 1
                        shadowOpacity: 0.5 + Viz.level * 0.3 + Viz.pulse * 0.2
                        autoPaddingEnabled: true
                    }
                }
            }

            // ── title, lyrics, controls ────────────────────
            ColumnLayout {
                Layout.preferredWidth: 640
                spacing: 6

                Txt { text: (Media.player?.identity ?? "").toUpperCase(); font.pixelSize: 12; font.weight: Font.Black; font.letterSpacing: 3; color: Theme.primary }
                GradientText {
                    Layout.maximumWidth: 640
                    text: Music.title || Media.title
                    font.pixelSize: 58; font.weight: Font.Black; font.letterSpacing: -1.5
                    maxWidth: 640; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    period: 5000
                }
                Txt { text: Music.artist || Media.artist; font.pixelSize: 24; font.weight: Font.Medium; color: Qt.alpha(Theme.text, 0.85); Layout.maximumWidth: 640 }

                // lyrics: the list scrolls so the current line sits in the middle
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    Layout.topMargin: 18
                    clip: true
                    visible: Music.hasLyrics
                    ListView {
                        id: lyr
                        anchors.fill: parent
                        model: Music.hasLyrics ? Music.lines : []
                        interactive: false
                        currentIndex: Music.lyricIndex
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        preferredHighlightBegin: height / 2 - 24
                        preferredHighlightEnd: height / 2 + 24
                        highlightMoveDuration: Theme.slow
                        spacing: 8
                        delegate: Txt {
                            required property string modelData
                            required property int index
                            readonly property int dist: Math.abs(index - Music.lyricIndex)
                            width: lyr.width
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            text: modelData
                            font.pixelSize: dist === 0 ? 30 : 22
                            font.weight: dist === 0 ? Font.Black : Font.Medium
                            color: dist === 0 ? Theme.mix(Theme.text, Theme.primary, 0.3 + Viz.pulse * 0.5) : Qt.alpha(Theme.text, Math.max(0.15, 0.55 - dist * 0.12))
                            Behavior on font.pixelSize { Anim { duration: Theme.normal } }
                        }
                    }
                }
                Txt {
                    visible: !Music.hasLyrics
                    Layout.topMargin: 18
                    text: Media.active ? "♪  no synced lyrics for this track" : "nothing playing"
                    font.pixelSize: 16; color: Qt.alpha(Theme.subtext, 0.7)
                }

                // progress + controls
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    Layout.topMargin: 18
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.alpha(Theme.text, 0.15) }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * Media.progress; height: 6 + Viz.pulse * 3; radius: 4
                        Behavior on width { Anim { duration: 900; easing.type: Easing.Linear } }
                        gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.magenta } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m => Media.seek(m.x / width) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Txt { text: Media.fmt(Media.position); font.family: Theme.mono; font.pixelSize: 12; color: Theme.subtext }
                    Item { Layout.fillWidth: true }
                    IconBtn { icon: "skip_previous"; size: 54; onClicked: Media.previous() }
                    IconBtn { icon: Media.playing ? "pause" : "play_arrow"; size: 70; active: true; onClicked: Media.toggle() }
                    IconBtn { icon: "skip_next"; size: 54; onClicked: Media.next() }
                    Item { Layout.fillWidth: true }
                    Txt { text: Media.fmt(Media.length); font.family: Theme.mono; font.pixelSize: 12; color: Theme.subtext }
                }
            }
        }
    }
}
