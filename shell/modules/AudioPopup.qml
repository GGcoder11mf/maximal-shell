import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.services
import qs.widgets

// Audio dropdown under the bar's volume control (click the speaker / percentage).
// Unrolls downward out of the bar: volume, mic, output device, per-app volumes with live meters.
Overlay {
    id: root
    name: "audio"
    frosted: false
    dim: 0.06
    grabKeyboard: false        // a volume dropdown shouldn't steal typing; click outside to close

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    // playback streams (apps making sound). Quickshell marks these isStream && isSink;
    // capture streams (e.g. our own visualiser) are isStream && !isSink.
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)
    PwObjectTracker { objects: [...root.sinks, ...root.streams] }

    function appName(n) {
        const p = n?.properties ?? {};
        return p["application.name"] || n?.nickname || n?.name || n?.description || "App";
    }
    function appIcon(n) {
        const p = n?.properties ?? {};
        const id = p["application.icon-name"] || p["application.process.binary"] || appName(n).toLowerCase();
        return Apps.icon(id, "audio-x-generic");
    }

    // ── the dropdown ─────────────────────────────────────
    Item {
        id: reveal
        width: 380
        x: Math.max(12, Math.min(parent.width - width - 12, Shell.audioAnchor - width / 2))
        y: 60
        height: (card.height + 14) * root.progress          // unrolls downward
        clip: true

        // little notch pointing at the speaker icon
        Rectangle {
            width: 16; height: 16; rotation: 45
            x: Shell.audioAnchor - reveal.x - width / 2
            y: 2
            color: Theme.glass
            opacity: root.progress
        }

        Glass {
            id: card
            y: 9 - (1 - root.progress) * 30
            width: parent.width
            height: col.implicitHeight + 34
            radius: 24
            fancy: true
            glow: true
            color: Qt.alpha(Theme.surface, 0.86)
            MouseArea { anchors.fill: parent }     // swallow clicks inside

            ColumnLayout {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 17
                spacing: 12

                // header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 44
                        radius: 14
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Audio.muted ? Theme.red : Theme.primary }
                            GradientStop { position: 1; color: Audio.muted ? Theme.orange : Theme.tertiary }
                        }
                        Icon {
                            anchors.centerIn: parent
                            icon: Audio.icon; size: 24; fill: 1; color: Theme.onPrimary
                            scale: 1 + Viz.pulse * 0.15
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMute() }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        GradientText { text: Audio.muted ? "muted" : "volume"; font.pixelSize: 20; font.weight: Font.Black; glow: false }
                        Txt { Layout.fillWidth: true; text: Audio.sinkName; font.pixelSize: 11; color: Theme.subtext }
                    }
                    Txt {
                        text: Math.round(Audio.volume * 100) + "%"
                        font.family: Theme.mono; font.pixelSize: 22; font.weight: Font.Black
                        color: Audio.muted ? Theme.red : Theme.text
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    icon: Audio.icon; value: Audio.volume; muted: Audio.muted; max: 1.0
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }
                Slider {
                    Layout.fillWidth: true
                    visible: !!Audio.source
                    icon: Audio.micIcon; value: Audio.micVolume; muted: Audio.micMuted; max: 1.0
                    onMoved: v => Audio.setMic(v)
                    onIconClicked: Audio.toggleMic()
                }

                // output devices
                Txt { visible: root.sinks.length > 1; text: "OUTPUT"; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.subtext }
                Flow {
                    Layout.fillWidth: true
                    visible: root.sinks.length > 1
                    spacing: 6
                    Repeater {
                        model: root.sinks
                        Rectangle {
                            id: dev
                            required property PwNode modelData
                            readonly property bool on: modelData === Pipewire.defaultAudioSink
                            width: Math.min(col.width, dl.implicitWidth + 40); height: 32; radius: 16
                            color: on ? "transparent" : dm.containsMouse ? Theme.glassHi : Theme.chip
                            gradient: on ? devGrad : null
                            Gradient { id: devGrad; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.tertiary } }
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Icon { icon: dev.modelData.description.toLowerCase().includes("hdmi") ? "tv" : dev.modelData.description.toLowerCase().includes("head") ? "headphones" : "speaker"; size: 15; fill: dev.on ? 1 : 0; color: dev.on ? Theme.onPrimary : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                                Txt { id: dl; text: dev.modelData.description || dev.modelData.name; font.pixelSize: 11; font.weight: Font.Bold; color: dev.on ? Theme.onPrimary : Theme.text; width: Math.min(implicitWidth, col.width - 50) }
                            }
                            MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink = dev.modelData }
                        }
                    }
                }

                // per-app volumes with live level meters
                Txt { visible: root.streams.length > 0; text: "APPS"; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.subtext }
                Repeater {
                    model: root.streams
                    ColumnLayout {
                        id: app
                        required property PwNode modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            IconImage { implicitSize: 18; source: root.appIcon(app.modelData) }
                            Txt { Layout.fillWidth: true; text: root.appName(app.modelData) + ((app.modelData.properties?.["media.name"] ?? "") ? "  ·  " + app.modelData.properties["media.name"] : ""); font.pixelSize: 11; color: Theme.subtext }
                        }
                        Slider {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            icon: app.modelData.audio?.muted ? "volume_off" : "music_note"
                            value: app.modelData.audio?.volume ?? 0
                            muted: app.modelData.audio?.muted ?? false
                            max: 1.0
                            onMoved: v => { if (app.modelData.audio) { app.modelData.audio.muted = false; app.modelData.audio.volume = v; } }
                            onIconClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted
                        }
                        // live level of this app (only measured while the dropdown is open)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 3
                            radius: 2
                            color: Theme.chip
                            Rectangle {
                                height: parent.height; radius: 2
                                width: parent.width * Math.min(1, meter.peak)
                                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.magenta } }
                            }
                            PwNodePeakMonitor { id: meter; node: app.modelData; enabled: root.open }
                        }
                    }
                }
                Txt {
                    visible: root.streams.length === 0
                    text: "No apps are playing audio"
                    font.pixelSize: 11; color: Qt.alpha(Theme.subtext, 0.7)
                }

                // footer
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Txt { text: "mixer"; font.pixelSize: 11; color: Theme.subtext }
                    IconBtn { icon: "tune"; size: 28; onClicked: { Shell.close(); Quickshell.execDetached(["pwvucontrol"]); } }
                }
            }
        }
    }
}
