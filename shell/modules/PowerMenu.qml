import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// Full-screen power menu. ←/→ or 1-6 to pick, Enter to fire; destructive actions need a second press.
Overlay {
    id: root
    name: "power"
    dim: 0.55

    property int sel: 0
    property int armed: -1
    onOpened: { sel = 0; armed = -1; keys.forceActiveFocus(); }

    readonly property var actions: [
        { icon: "lock",               label: "Lock",      cmd: ["hyprlock", "-c", Theme.rice + "/hyprlock.conf"], confirm: false, tint: Theme.primary },
        { icon: "bedtime",            label: "Suspend",   cmd: ["systemctl", "suspend"],                          confirm: false, tint: Theme.tertiary },
        { icon: "logout",             label: "Log out",   cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"],          confirm: true,  tint: Theme.yellow },
        { icon: "restart_alt",        label: "Reboot",    cmd: ["systemctl", "reboot"],                           confirm: true,  tint: Theme.orange },
        { icon: "developer_board",    label: "Firmware",  cmd: ["systemctl", "reboot", "--firmware-setup"],       confirm: true,  tint: Theme.cyan },
        { icon: "power_settings_new", label: "Shut down", cmd: ["systemctl", "poweroff"],                         confirm: true,  tint: Theme.red }
    ]

    function fire(i) {
        const a = actions[i];
        if (a.confirm && armed !== i) { armed = i; sel = i; return; }
        Shell.close();
        Quickshell.execDetached(["sh", "-c", "sleep 0.35; exec \"$0\" \"$@\"", ...a.cmd]);
    }

    Item {
        id: keys
        anchors.fill: parent
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Tab) root.sel = (root.sel + 1) % root.actions.length;
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_Backtab) root.sel = (root.sel + root.actions.length - 1) % root.actions.length;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) root.fire(root.sel);
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_6) root.fire(e.key - Qt.Key_1);
            else if (e.key === Qt.Key_Escape) Shell.close();
            else return;
            if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space && !(e.key >= Qt.Key_1 && e.key <= Qt.Key_6)) root.armed = -1;
            e.accepted = true;
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 34
        opacity: root.progress
        scale: 0.9 + 0.1 * root.progress

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            GradientText {
                Layout.alignment: Qt.AlignHCenter
                text: "see you soon"
                font.pixelSize: 72; font.weight: Font.Black; font.letterSpacing: -3
                period: 4000
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: "up " + Sys.uptime + "   ·   " + Quickshell.env("USER") + "@" + Sys.hostname
                font.family: Theme.mono; font.pixelSize: 13; color: Theme.subtext
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            Repeater {
                model: root.actions
                Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool isSel: root.sel === index
                    readonly property bool isArmed: root.armed === index
                    readonly property real p: Math.max(0, Math.min(1, (root.progress - index * 0.06) / 0.6))
                    width: 150; height: 180
                    opacity: p
                    transform: Translate { y: (1 - tile.p) * (120 + tile.index * 30) }

                    Glass {
                        anchors.fill: parent
                        radius: 30
                        fancy: tile.isSel
                        glow: tile.isSel
                        period: tile.isArmed ? 900 : 4000
                        color: tile.isArmed ? Qt.alpha(tile.modelData.tint, 0.28) : tile.isSel ? Theme.glassHi : Theme.glass
                        scale: tile.isSel ? 1.1 : ma.containsMouse ? 1.04 : 1
                        y: tile.isSel ? -10 : 0
                        Behavior on scale { Anim { duration: Theme.normal; easing.type: Theme.springy } }
                        Behavior on y { Anim { duration: Theme.normal; easing.type: Theme.springy } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 14
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 76; height: 76; radius: 38
                                color: Qt.alpha(tile.modelData.tint, tile.isSel ? 0.95 : 0.16)
                                Behavior on color { CAnim {} }
                                Icon {
                                    anchors.centerIn: parent
                                    icon: tile.modelData.icon
                                    size: 38
                                    fill: tile.isSel ? 1 : 0
                                    weight: 600
                                    color: tile.isSel ? Theme.surface : tile.modelData.tint
                                    rotation: tile.isSel ? 360 : 0
                                    Behavior on rotation { Anim { duration: Theme.slow * 1.4; easing.type: Theme.springy } }
                                }
                                SequentialAnimation on scale {
                                    running: tile.isArmed; loops: Animation.Infinite
                                    NumberAnimation { to: 1.12; duration: 350; easing.type: Easing.OutQuad }
                                    NumberAnimation { to: 1.0; duration: 350; easing.type: Easing.InQuad }
                                    onRunningChanged: if (!running) parent.scale = 1
                                }
                            }
                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.isArmed ? "again to confirm" : tile.modelData.label
                                font.pixelSize: tile.isArmed ? 12 : 16
                                font.weight: Font.Black
                                color: tile.isArmed ? tile.modelData.tint : Theme.text
                            }
                            Keycap { anchors.horizontalCenter: parent.horizontalCenter; text: tile.index + 1; tint: tile.modelData.tint; opacity: 0.8 }
                        }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { if (root.sel !== tile.index) root.armed = -1; root.sel = tile.index; }
                        onClicked: root.fire(tile.index)
                    }
                }
            }
        }

        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: "←  →  select     ↵  confirm     1–6  quick pick     esc  cancel"
            font.family: Theme.mono; font.pixelSize: 12; color: Qt.alpha(Theme.subtext, 0.7)
        }
    }
}
