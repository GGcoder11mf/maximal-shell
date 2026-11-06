import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Alt+Tab window switcher: live previews in most-recently-used order.
// Hold Alt, tap Tab (Shift+Tab back) to move, release Alt to switch. Esc cancels, click picks.
// Hyprland owns the Alt+Tab binds (global maxi:switcher / maxi:switcherPrev); the Alt *release*
// arrives here as a normal key event because the switcher holds keyboard focus.
Overlay {
    id: root
    name: "switcher"
    dim: 0.35
    openDuration: Theme.normal

    property var wins: []
    property int sel: 0

    function build() {
        const list = Hyprland.toplevels.values.filter(t => t.lastIpcObject && !(t.lastIpcObject.workspace?.name ?? "").startsWith("special:"));
        list.sort((a, b) => (a.lastIpcObject.focusHistoryID ?? 99) - (b.lastIpcObject.focusHistoryID ?? 99));
        wins = list;
        sel = list.length > 1 ? 1 : 0;
    }
    function step(d) {
        if (!open) { Hyprland.refreshToplevels(); Shell.open("switcher"); return; }
        if (wins.length) sel = (sel + d + wins.length) % wins.length;
    }
    // Commit: close INSTANTLY, then focus. When an overlay with exclusive keyboard focus goes
    // away, Hyprland re-focuses on its own (the window under the pointer, with follow_mouse) —
    // that used to win and land you back on the old window. So focus after the overlay is gone,
    // and once more a little later in case Hyprland's re-focus came in between.
    property string pending: ""
    function commit() {
        const w = wins[sel];
        pending = w ? (String(w.address).startsWith("0x") ? w.address : "0x" + w.address) : "";
        root.openDuration = 0;            // no fade-out: release the keyboard right away
        Shell.close();
        focusSoon.restart();
    }
    function focusPending() { if (pending) Hyprland.dispatch(`hl.dsp.focus({ window = "address:${pending}" })`); }
    Timer { id: focusSoon; interval: 60; onTriggered: { root.focusPending(); focusAgain.restart(); } }
    Timer {
        id: focusAgain; interval: 120
        onTriggered: {
            if (root.pending && Hyprland.activeToplevel && ("0x" + String(Hyprland.activeToplevel.address).replace(/^0x/, "")) !== root.pending) root.focusPending();
            root.pending = "";
            root.openDuration = Theme.normal;
        }
    }

    onOpened: { build(); keys.forceActiveFocus(); rebuild.restart(); }
    Timer { id: rebuild; interval: 90; onTriggered: { const s = root.sel; root.build(); root.sel = Math.min(s, Math.max(0, root.wins.length - 1)); } }
    Connections { target: Shell; function onSwitcherStep(dir: int): void { root.step(dir); } }
    Connections {   // refreshToplevels is async: rebuild once fresh data lands
        target: Hyprland.toplevels
        function onValuesChanged() { if (root.open && root.wins.length === 0) root.build(); }
    }

    Item {
        id: keys
        anchors.fill: parent
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) root.step(1);
            else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) root.step(-1);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.commit();
            else if (e.key === Qt.Key_Escape) Shell.close();
            else return;
            e.accepted = true;
        }
        Keys.onReleased: e => { if (e.key === Qt.Key_Alt || e.key === Qt.Key_Meta) { root.commit(); e.accepted = true; } }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 18
        opacity: root.progress
        scale: 0.9 + 0.1 * root.progress

        Row {
            id: strip
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            Repeater {
                model: root.open ? root.wins : []
                Item {
                    id: card
                    required property HyprlandToplevel modelData
                    required property int index
                    readonly property bool cur: index === root.sel
                    readonly property var ipc: modelData.lastIpcObject
                    readonly property real aspect: (ipc?.size?.[0] ?? 16) / Math.max(1, ipc?.size?.[1] ?? 9)
                    width: Math.min(340, Math.max(170, 200 * aspect)); height: 230
                    opacity: 0
                    transform: Translate { id: tr; y: 30 }
                    Component.onCompleted: enter.start()
                    ParallelAnimation {
                        id: enter
                        SequentialAnimation { PauseAnimation { duration: Math.min(card.index, 8) * 35 } Anim { target: card; property: "opacity"; to: 1; duration: Theme.normal } }
                        SequentialAnimation { PauseAnimation { duration: Math.min(card.index, 8) * 35 } Anim { target: tr; property: "y"; to: 0; duration: Theme.slow; easing.type: Theme.springy } }
                    }

                    Glass {
                        anchors.fill: parent
                        radius: 22
                        fancy: card.cur
                        glow: card.cur
                        color: card.cur ? Theme.glassHi : Theme.glass
                        scale: card.cur ? 1.08 : 0.94
                        Behavior on scale { Anim { duration: Theme.normal; easing.type: Theme.springy } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            ClippingRectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: Theme.surfaceLow
                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: root.open ? card.modelData.wayland : null
                                    live: root.open && card.cur
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                IconImage {
                                    implicitSize: 22
                                    source: Apps.icon(Apps.classOf(card.modelData), "application-x-executable")
                                }
                                Txt {
                                    Layout.fillWidth: true
                                    text: card.modelData.title
                                    font.pixelSize: 12
                                    font.weight: card.cur ? Font.Bold : Font.Medium
                                    color: card.cur ? Theme.text : Theme.subtext
                                }
                                Keycap { text: card.ipc?.workspace?.id ?? "?"; visible: (card.ipc?.workspace?.id ?? 0) > 0 }
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.sel = card.index
                        onClicked: { root.sel = card.index; root.commit(); }
                    }
                }
            }
        }
        Txt {
            Layout.alignment: Qt.AlignHCenter
            visible: root.wins.length === 0
            text: "No windows open"
            font.pixelSize: 18; color: Theme.subtext
        }
        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: "tab / shift+tab  ·  release alt to switch  ·  esc cancel"
            font.family: Theme.mono; font.pixelSize: 11; color: Qt.alpha(Theme.subtext, 0.75)
        }
    }
}
