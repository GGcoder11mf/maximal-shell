import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.widgets

// Drop-down dashboard: profile · clock · weather / media · calendar / system.
Overlay {
    id: root
    name: "dashboard"
    frosted: false
    dim: 0.18

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // card i appears when progress passes its threshold -> cascade
    function stagger(i) { return Math.max(0, Math.min(1, (root.progress - i * 0.07) / 0.55)); }

    component Card: Glass {
        id: c
        property int order: 0
        readonly property real p: root.stagger(order)
        opacity: p
        transform: Translate { y: (1 - c.p) * -40 }
        scale: 0.94 + 0.06 * p
        radius: 24
        MouseArea { anchors.fill: parent }
    }

    Item {
        id: frame
        width: 1040
        height: grid.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        y: 70

        GridLayout {
            id: grid
            width: parent.width
            columns: 3
            columnSpacing: 12
            rowSpacing: 12

            // ── PROFILE ───────────────────────────────────
            Card {
                order: 0
                Layout.preferredWidth: 300
                Layout.preferredHeight: 230
                fancy: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 96
                        GlowBorder { radius: 48; thickness: 4; glow: true; period: 3000 }
                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 7
                            radius: width / 2
                            color: Theme.primaryContainer
                            Image { anchors.fill: parent; source: "file://" + Theme.home + "/.face"; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(180, 180) }
                        }
                    }
                    GradientText { Layout.alignment: Qt.AlignHCenter; text: Sys.userName; font.pixelSize: 24; font.weight: Font.Black }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰣇  " + Quickshell.env("USER") + "@" + Sys.hostname
                        font.family: Theme.mono; font.pixelSize: 11; color: Theme.subtext
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6
                        Icon { icon: "timer"; size: 15; color: Theme.tertiary; fill: 1; anchors.verticalCenter: parent.verticalCenter }
                        Txt { text: "up " + Sys.uptime; font.pixelSize: 12; color: Theme.subtext }
                    }
                }
            }

            // ── CLOCK ─────────────────────────────────────
            Card {
                order: 1
                Layout.preferredWidth: 400
                Layout.preferredHeight: 230
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const h = clock.date.getHours();
                            return h < 5 ? "Burning the midnight oil" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
                        }
                        font.pixelSize: 14; font.letterSpacing: 2; color: Theme.subtext
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        GradientText { text: Qt.formatDateTime(clock.date, "HH:mm"); font.pixelSize: 96; font.weight: Font.Black; font.letterSpacing: -4; period: 5000 }
                        Txt {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 22
                            leftPadding: 6
                            text: Qt.formatDateTime(clock.date, "ss")
                            font.family: Theme.mono; font.pixelSize: 24; font.weight: Font.Bold; color: Theme.tertiary
                        }
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "dddd · d MMMM yyyy").toUpperCase()
                        font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 3; color: Theme.primary
                    }
                    // day progress
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 14
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: 6
                        readonly property real day: (clock.date.getHours() * 3600 + clock.date.getMinutes() * 60 + clock.date.getSeconds()) / 86400
                        Rectangle { anchors.fill: parent; radius: 3; color: Theme.chip }
                        Rectangle {
                            width: parent.width * parent.day; height: parent.height; radius: 3
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.magenta } }
                        }
                        Txt { anchors.top: parent.bottom; anchors.topMargin: 4; anchors.right: parent.right; text: Math.round(parent.day * 100) + "% of today"; font.pixelSize: 10; color: Theme.subtext }
                    }
                }
            }

            // ── WEATHER ───────────────────────────────────
            Card {
                order: 2
                Layout.preferredWidth: 316
                Layout.preferredHeight: 230
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 6
                    RowLayout {
                        spacing: 12
                        Icon {
                            icon: Weather.currentIcon; size: 64; fill: 1
                            color: Weather.night ? Theme.secondary : Theme.yellow
                            SequentialAnimation on y {
                                running: !Theme.calm && root.open; loops: Animation.Infinite
                                NumberAnimation { to: -5; duration: 1600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 1600; easing.type: Easing.InOutSine }
                            }
                            RotationAnimator on rotation { running: Weather.currentIcon === "sunny" && !Theme.calm && root.open; from: 0; to: 360; duration: 30000; loops: Animation.Infinite }
                        }
                        ColumnLayout {
                            spacing: -4
                            GradientText { text: Weather.temp + "°"; font.pixelSize: 48; font.weight: Font.Black }
                            Txt { text: "feels " + Weather.feels + "°"; font.pixelSize: 11; color: Theme.subtext }
                        }
                        Item { Layout.fillWidth: true }
                        ColumnLayout {
                            spacing: 2
                            Txt { Layout.alignment: Qt.AlignRight; text: "↑ " + Weather.high + "°"; font.family: Theme.mono; font.pixelSize: 12; color: Theme.orange }
                            Txt { Layout.alignment: Qt.AlignRight; text: "↓ " + Weather.low + "°"; font.family: Theme.mono; font.pixelSize: 12; color: Theme.cyan }
                        }
                    }
                    Txt { Layout.fillWidth: true; text: Weather.desc; font.pixelSize: 15; font.weight: Font.Bold }
                    Txt { Layout.fillWidth: true; text: "📍 " + (Weather.location || "—") + "   💧 " + Weather.humidity + "%   🌬 " + Weather.wind + " km/h"; font.pixelSize: 11; color: Theme.subtext }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: Weather.hourly.filter((h, i) => i % 1 === 0).slice(0, 8)
                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 1
                                Txt { Layout.alignment: Qt.AlignHCenter; text: parent.modelData.time.slice(0, 2); font.family: Theme.mono; font.pixelSize: 9; color: Theme.subtext }
                                Icon { Layout.alignment: Qt.AlignHCenter; icon: Weather.icon(parent.modelData.code, false); size: 16; fill: 1; color: Theme.primary }
                                Txt { Layout.alignment: Qt.AlignHCenter; text: parent.modelData.temp + "°"; font.pixelSize: 10; font.weight: Font.Bold }
                            }
                        }
                    }
                }
            }

            // ── MEDIA ─────────────────────────────────────
            Card {
                order: 3
                Layout.columnSpan: 2
                Layout.preferredWidth: 712
                Layout.preferredHeight: 220

                // blurred art backdrop
                ClippingRectangle {
                    anchors.fill: parent
                    radius: 24
                    color: "transparent"
                    opacity: artBg.status === Image.Ready ? 0.55 : 0
                    Behavior on opacity { Anim { duration: Theme.slow } }
                    Image {
                        id: artBg
                        anchors.fill: parent
                        anchors.margins: -40
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(256, 256)
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 64; saturation: 0.3; brightness: -0.15 }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    // art "vinyl" + radial spectrum ring
                    Item {
                        id: vinylBox
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 170
                        scale: 1 + Viz.pulse * 0.04

                        Repeater {
                            model: root.open ? 64 : 0              // always there; rests as dots when silent
                            Rectangle {
                                required property int index
                                readonly property real v: Viz.values[index < 32 ? index : 63 - index] ?? 0
                                width: 3
                                height: 4 + v * 40
                                radius: 1.5
                                x: vinylBox.width / 2 - width / 2
                                y: -height + 1
                                transform: Rotation { origin.x: 1.5; origin.y: height + 84; angle: index * 360 / 64 }
                                color: Theme.mix(Theme.primary, Theme.magenta, v)
                                opacity: 0.55 + v * 0.45
                            }
                        }
                        Rectangle {
                            id: vinyl
                            anchors.fill: parent
                            radius: width / 2
                            color: "#0b0b0e"
                            border.width: 2
                            border.color: Qt.alpha(Theme.primary, 0.4)
                            RotationAnimator on rotation { from: 0; to: 360; duration: 6000; loops: Animation.Infinite; running: Media.playing && !Theme.calm && root.open }
                            Repeater {
                                model: 5
                                Rectangle {
                                    required property int index
                                    anchors.centerIn: parent
                                    width: parent.width - 16 - index * 12; height: width; radius: width / 2
                                    color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.05)
                                }
                            }
                            ClippingRectangle {
                                anchors.centerIn: parent
                                width: 92; height: 92; radius: 46
                                color: Theme.primaryContainer
                                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(200, 200) }
                                Icon { anchors.centerIn: parent; visible: !Media.art; icon: "album"; size: 40; color: Theme.onPrimaryContainer }
                            }
                            Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: Theme.surface }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        RowLayout {
                            Txt { text: (Media.player?.identity ?? "No player").toUpperCase(); font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.primary }
                            Item { Layout.fillWidth: true }
                            Visualizer { height: 18; bars: 12; barWidth: 3 }
                        }
                        Marquee { Layout.fillWidth: true; text: Media.title; font.pixelSize: 24; font.weight: Font.Black }
                        Txt { Layout.fillWidth: true; text: Media.artist + (Media.album ? "  ·  " + Media.album : ""); font.pixelSize: 13; color: Theme.subtext }
                        Item { Layout.fillHeight: true }
                        // seek bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.chip }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * Media.progress; height: 6; radius: 3
                                Behavior on width { Anim { duration: 900; easing.type: Easing.Linear } }
                                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.magenta } }
                                Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: Theme.text }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m => Media.seek(m.x / width) }
                        }
                        RowLayout {
                            Txt { text: Media.fmt(Media.position); font.family: Theme.mono; font.pixelSize: 11; color: Theme.subtext }
                            Item { Layout.fillWidth: true }
                            IconBtn { icon: "shuffle"; size: 34; active: Media.player?.shuffle ?? false; onClicked: if (Media.player?.shuffleSupported) Media.player.shuffle = !Media.player.shuffle }
                            IconBtn { icon: "skip_previous"; size: 40; onClicked: Media.previous() }
                            IconBtn { icon: Media.playing ? "pause" : "play_arrow"; size: 52; active: true; onClicked: Media.toggle() }
                            IconBtn { icon: "skip_next"; size: 40; onClicked: Media.next() }
                            IconBtn { icon: "swap_horiz"; size: 34; visible: Media.players.length > 1; onClicked: Media.cycle() }
                            Item { Layout.fillWidth: true }
                            Txt { text: Media.fmt(Media.length); font.family: Theme.mono; font.pixelSize: 11; color: Theme.subtext }
                        }
                    }
                }
            }

            // ── CALENDAR ──────────────────────────────────
            Card {
                order: 4
                Layout.rowSpan: 2
                Layout.preferredWidth: 316
                Layout.fillHeight: true
                Calendar { anchors.fill: parent; anchors.margins: 16; today: clock.date }
            }

            // ── SYSTEM ────────────────────────────────────
            Card {
                order: 5
                Layout.columnSpan: 2
                Layout.preferredWidth: 712
                Layout.preferredHeight: 170
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 18
                    Repeater {
                        model: [
                            { v: Sys.cpu, i: "memory", l: "CPU", t: Math.round(Sys.cpu * 100) + "%", c: Theme.primary },
                            { v: Sys.mem, i: "memory_alt", l: "RAM", t: Sys.memUsedGb.toFixed(1) + "G", c: Theme.tertiary },
                            { v: Sys.disk, i: "hard_drive", l: "DISK", t: Math.round(Sys.disk * 100) + "%", c: Theme.magenta },
                            { v: Sys.temp / 100, i: "device_thermostat", l: "TEMP", t: Math.round(Sys.temp) + "°", c: Theme.orange }
                        ]
                        ColumnLayout {
                            required property var modelData
                            spacing: 4
                            Ring { Layout.preferredWidth: 84; Layout.preferredHeight: 84; thickness: 8; value: parent.modelData.v; color: parent.modelData.c; icon: parent.modelData.i; label: parent.modelData.t; iconSize: 20 }
                            Txt { Layout.alignment: Qt.AlignHCenter; text: parent.modelData.l; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.subtext }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        RowLayout {
                            Txt { text: "CPU HISTORY"; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.subtext }
                            Item { Layout.fillWidth: true }
                            Txt { text: "↓ " + Sys.bytes(Sys.rx) + "/s  ↑ " + Sys.bytes(Sys.tx) + "/s"; font.family: Theme.mono; font.pixelSize: 10; color: Theme.cyan }
                        }
                        Graph { Layout.fillWidth: true; Layout.fillHeight: true; values: Sys.cpuHistory; color: Theme.primary }
                        Graph { Layout.fillWidth: true; Layout.preferredHeight: 30; values: Sys.netHistory; autoScale: true; color: Theme.cyan }
                    }
                }
            }
        }
    }
}
