import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.services
import qs.widgets

// Right-side control center: quick toggles, sliders, devices, notification history.
Overlay {
    id: root
    name: "control"
    frosted: false
    dim: 0.12

    onOpened: Notifs.unseen = 0

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDev: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiNet: wifiDev?.networks?.values?.find(n => n.connected) ?? null
    readonly property var btDevices: (bt?.devices?.values ?? []).filter(d => d.paired || d.connected)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function stagger(i) { return Math.max(0, Math.min(1, (root.progress - i * 0.06) / 0.6)); }

    Glass {
        id: panel
        width: 440
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 66
        anchors.bottomMargin: 12
        x: parent.width - (width + 12) * root.progress
        radius: Theme.radiusLg
        fancy: true
        glow: true
        color: Qt.alpha(Theme.surface, 0.84)
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // ── header ────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                opacity: root.stagger(0)
                spacing: 12
                ClippingRectangle {
                    Layout.preferredWidth: 46; Layout.preferredHeight: 46; radius: 23
                    color: Theme.primaryContainer
                    Image { anchors.fill: parent; source: "file://" + Theme.home + "/.face"; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(96, 96) }
                }
                ColumnLayout {
                    spacing: 0
                    GradientText { text: Qt.formatDateTime(clock.date, "HH:mm"); font.pixelSize: 24; font.weight: Font.Black; glow: false }
                    Txt { text: Qt.formatDateTime(clock.date, "dddd, d MMMM") + "  ·  up " + Sys.uptime; font.pixelSize: 11; color: Theme.subtext }
                }
                Item { Layout.fillWidth: true }
                IconBtn { icon: "screenshot_region"; onClicked: { Shell.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.4; " + Theme.scripts + "screenshot.sh freeze"]); } }
                IconBtn { icon: "wallpaper"; onClicked: Shell.open("wallpapers") }
                IconBtn { icon: "lock"; onClicked: { Shell.close(); Quickshell.execDetached(["hyprlock", "-c", Theme.rice + "/hyprlock.conf"]); } }
                IconBtn { icon: "power_settings_new"; iconColor: Theme.red; onClicked: Shell.open("power") }
            }

            // ── toggles ───────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                opacity: root.stagger(1)
                transform: Translate { x: (1 - root.stagger(1)) * 60 }

                Tile {
                    Layout.fillWidth: true
                    icon: root.wiredDev ? "lan" : Networking.wifiEnabled ? "wifi" : "wifi_off"
                    label: root.wiredDev ? "Ethernet" : "Wi-Fi"
                    sublabel: root.wiredDev ? "Connected" : root.wifiNet ? root.wifiNet.name : Networking.wifiEnabled ? "Not connected" : "Off"
                    active: !!root.wiredDev || (Networking.wifiEnabled && !!root.wifiNet)
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    onRightClicked: Quickshell.execDetached(["foot", "-c", Theme.rice + "/foot.ini", "-e", "nmtui"])
                }
                Tile {
                    Layout.fillWidth: true
                    icon: root.bt?.enabled ? "bluetooth" : "bluetooth_disabled"
                    label: "Bluetooth"
                    sublabel: !root.bt ? "No adapter" : !root.bt.enabled ? "Off" : (root.btDevices.filter(d => d.connected).map(d => d.name).join(", ") || "On")
                    active: root.bt?.enabled ?? false
                    onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "do_not_disturb_on"; label: "Do not disturb"
                    sublabel: Shell.dnd ? "Popups silenced" : "Off"
                    active: Shell.dnd
                    onClicked: Shell.dnd = !Shell.dnd
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "coffee"; label: "Caffeine"
                    sublabel: Shell.caffeine ? "Staying awake" : "Off"
                    active: Shell.caffeine
                    onClicked: Shell.caffeine = !Shell.caffeine
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "sports_esports"; label: "Game mode"
                    sublabel: Shell.gameMode ? "Eye candy off" : "Off"
                    active: Shell.gameMode
                    onClicked: Shell.hypr("MAXI.modes.toggle_game()")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "nightlight"; label: "Night light"
                    sublabel: Shell.shader === "nightlight" ? "Warm" : Shell.shader ? Shell.shader : "Off"
                    active: Shell.shader === "nightlight"
                    onClicked: Shell.hypr("MAXI.modes.toggle_nightlight()")
                    onRightClicked: Shell.hypr("MAXI.modes.cycle_shader()")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: Audio.micIcon; label: "Microphone"
                    sublabel: !Audio.source ? "No input" : Audio.micMuted ? "Muted" : Math.round(Audio.micVolume * 100) + "%"
                    active: !!Audio.source && !Audio.micMuted
                    onClicked: Audio.toggleMic()
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "radio_button_checked"; label: "Record"
                    sublabel: Shell.recording ? "Recording…" : "Screen"
                    active: Shell.recording
                    onClicked: { if (!Shell.recording) Shell.close(); Quickshell.execDetached(["sh", "-c", (Shell.recording ? "" : "sleep 0.5; ") + Theme.scripts + "record.sh"]); }
                    onRightClicked: { Shell.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.5; " + Theme.scripts + "record.sh region"]); }
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "graphic_eq"; label: "Audio reactive"
                    sublabel: !Shell.audioReactive ? "Off" : Viz.level < 0.02 ? "Listening…" : Viz.bpm > 0 ? "♪ " + Viz.bpm + " bpm" : "Reacting"
                    active: Shell.audioReactive
                    onClicked: Shell.audioReactive = !Shell.audioReactive
                    onRightClicked: { Shell.beatBorders = !Shell.beatBorders; Toaster.show("Beat borders", Shell.beatBorders ? "ON" : "OFF", "border_outer"); }
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "palette"; label: "Album colours"
                    sublabel: !Shell.albumColors ? "Off" : Media.playing ? "Theming from cover" : "On"
                    active: Shell.albumColors
                    onClicked: Shell.albumColors = !Shell.albumColors
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "theater_comedy"; label: "Music stage"
                    sublabel: Shell.stageAuto ? "Auto when idle · right-click" : "Manual · right-click"
                    active: Shell.panel === "stage"
                    onClicked: Shell.open("stage")
                    onRightClicked: Shell.stageAuto = !Shell.stageAuto
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "auto_awesome"; label: "Screen effect"
                    sublabel: Shell.shader || "Off"
                    active: Shell.shader !== ""
                    onClicked: Shell.hypr("MAXI.modes.cycle_shader()")
                }
            }

            // ── sliders ───────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                opacity: root.stagger(2)
                transform: Translate { x: (1 - root.stagger(2)) * 60 }
                Txt { text: "OUTPUT  ·  " + Audio.sinkName; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 1.5; color: Theme.subtext; Layout.fillWidth: true }
                Slider {
                    Layout.fillWidth: true
                    icon: Audio.icon; value: Audio.volume; muted: Audio.muted; max: 1.0
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }
                Txt { text: "INPUT  ·  " + Audio.sourceName; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 1.5; color: Theme.subtext; Layout.fillWidth: true }
                Slider {
                    Layout.fillWidth: true
                    icon: Audio.micIcon; value: Audio.micVolume; muted: Audio.micMuted; max: 1.0
                    onMoved: v => Audio.setMic(v)
                    onIconClicked: Audio.toggleMic()
                }

                // ── music reactivity: intensity + mood ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Txt {
                        text: "MUSIC  ·  " + (!Shell.audioReactive ? "off" : Viz.active ? (Viz.bpm > 0 ? Viz.bpm + " bpm · " : "") + Viz.mood : "listening")
                        font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 1.5; color: Theme.subtext
                        Layout.fillWidth: true
                    }
                }
                Slider {
                    Layout.fillWidth: true
                    icon: "graphic_eq"
                    value: Shell.vizIntensity
                    max: 1.0
                    muted: !Shell.audioReactive
                    onMoved: v => Shell.vizIntensity = Math.round(v * 20) / 20
                    onIconClicked: Shell.audioReactive = !Shell.audioReactive
                }
                Row {
                    spacing: 6
                    Repeater {
                        model: [["auto", "auto_awesome", "Auto"], ["chill", "spa", "Chill"], ["groove", "music_note", "Groove"], ["hype", "local_fire_department", "Hype"]]
                        Rectangle {
                            id: chip
                            required property var modelData
                            readonly property bool on: Shell.vizMood === modelData[0]
                            width: chipRow.implicitWidth + 22; height: 32; radius: 16
                            color: on ? "transparent" : cm.containsMouse ? Theme.glassHi : Theme.chip
                            gradient: on ? chipGrad : null
                            Gradient { id: chipGrad; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.tertiary } }
                            scale: cm.pressed ? 0.92 : 1
                            Behavior on scale { Anim { easing.type: Theme.springy } }
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 5
                                Icon { icon: chip.modelData[1]; size: 15; fill: chip.on ? 1 : 0; color: chip.on ? Theme.onPrimary : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                                Txt {
                                    // Auto shows what it currently detects
                                    text: chip.modelData[0] === "auto" && chip.on && Viz.active ? "Auto · " + Viz.detectedMood : chip.modelData[2]
                                    font.pixelSize: 12; font.weight: Font.Bold
                                    color: chip.on ? Theme.onPrimary : Theme.text
                                }
                            }
                            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Shell.vizMood = chip.modelData[0] }
                        }
                    }
                }
            }

            // ── bluetooth devices ─────────────────────
            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: !!(root.bt?.enabled) && root.btDevices.length > 0
                opacity: root.stagger(3)
                Repeater {
                    model: root.btDevices
                    Rectangle {
                        required property var modelData
                        width: bl.implicitWidth + 40; height: 30; radius: 15
                        color: modelData.connected ? Qt.alpha(Theme.cyan, 0.22) : Theme.chip
                        border.width: modelData.connected ? 1 : 0
                        border.color: Theme.cyan
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Icon { icon: parent.parent.modelData.connected ? "bluetooth_connected" : "bluetooth"; size: 15; fill: 1; color: Theme.cyan }
                            Txt { id: bl; text: parent.parent.modelData.name + (parent.parent.modelData.batteryAvailable ? "  " + Math.round(parent.parent.modelData.battery * 100) + "%" : ""); font.pixelSize: 11 }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.connected ? parent.modelData.disconnect() : parent.modelData.connect()
                        }
                    }
                }
            }

            // ── notifications ─────────────────────────
            RowLayout {
                Layout.fillWidth: true
                opacity: root.stagger(4)
                Icon { icon: "notifications"; size: 18; fill: 1; color: Theme.primary }
                Txt { text: "Notifications"; font.pixelSize: 15; font.weight: Font.Black }
                Rectangle {
                    visible: Notifs.count > 0
                    width: nc.implicitWidth + 12; height: 20; radius: 10; color: Theme.primary
                    Txt { id: nc; anchors.centerIn: parent; text: Notifs.count; font.pixelSize: 10; font.weight: Font.Black; color: Theme.onPrimary }
                }
                Item { Layout.fillWidth: true }
                IconBtn { icon: Shell.dnd ? "notifications_off" : "notifications_active"; size: 30; active: Shell.dnd; onClicked: Shell.dnd = !Shell.dnd }
                IconBtn { icon: "clear_all"; size: 30; onClicked: Notifs.clear() }
            }

            ListView {
                id: hist
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: root.stagger(5)
                clip: true
                spacing: 8
                model: ScriptModel { values: [...Notifs.all] }
                delegate: NotifCard {
                    required property QtObject modelData
                    entry: modelData
                    popup: false
                    width: hist.width
                    color: Theme.chip
                }
                add: Transition { NumberAnimation { property: "x"; from: 300; to: 0; duration: Theme.slow; easing.type: Easing.OutBack } }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "x"; to: 460; duration: Theme.normal; easing.type: Easing.InCubic }
                        NumberAnimation { property: "opacity"; to: 0; duration: Theme.normal }
                    }
                }
                displaced: Transition { NumberAnimation { property: "y"; duration: Theme.slow; easing.type: Easing.OutBack } }

                Column {
                    anchors.centerIn: parent
                    visible: Notifs.count === 0
                    spacing: 8
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: "notifications_paused"; size: 56; color: Qt.alpha(Theme.subtext, 0.4)
                        SequentialAnimation on rotation {
                            running: root.open && !Theme.calm; loops: Animation.Infinite
                            NumberAnimation { to: 8; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: -8; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                    Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "All caught up"; color: Theme.subtext; font.pixelSize: 13 }
                }
            }
        }
    }
}
