import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Workspace overview with live window previews.
// Click a window: focus it · drag a window onto another workspace: move it · click empty space: go there.
Overlay {
    id: root
    name: "overview"
    dim: 0.45

    readonly property HyprlandMonitor mon: Hyprland.focusedMonitor
    readonly property real monW: (mon?.width ?? 1920) / (mon?.scale ?? 1)
    readonly property real monH: (mon?.height ?? 1080) / (mon?.scale ?? 1)
    readonly property real monX: mon?.x ?? 0
    readonly property real monY: mon?.y ?? 0
    readonly property int count: Math.min(10, Math.max(6, ...Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id)))
    readonly property int cols: count > 8 ? 5 : count > 6 ? 4 : 3
    readonly property real cellW: Math.min((width - 160 - (cols - 1) * 22) / cols, 420)
    readonly property real s: cellW / monW
    readonly property real cellH: monH * s
    property int sel: 1

    onOpened: {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        sel = Hyprland.focusedWorkspace?.id ?? 1;
        keys.forceActiveFocus();
    }

    function go(id) { Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`); Shell.close(); }

    Item {
        id: keys
        anchors.fill: parent
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Right || e.key === Qt.Key_L) root.sel = Math.min(root.count, root.sel + 1);
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) root.sel = Math.max(1, root.sel - 1);
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) root.sel = Math.min(root.count, root.sel + root.cols);
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.sel = Math.max(1, root.sel - root.cols);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.go(root.sel);
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) root.go(e.key - Qt.Key_0);
            else if (e.key === Qt.Key_Escape || e.key === Qt.Key_Tab) Shell.close();
            else return;
            e.accepted = true;
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 26
        opacity: root.progress
        scale: 0.92 + 0.08 * root.progress

        RowLayout {
            Layout.fillWidth: true
            GradientText { text: "overview"; font.pixelSize: 48; font.weight: Font.Black; font.letterSpacing: -2 }
            Item { Layout.fillWidth: true }
            Txt { text: "click: focus   ·   drag: move   ·   ←↑↓→ ↵: jump"; font.family: Theme.mono; font.pixelSize: 12; color: Theme.subtext }
        }

        Grid {
            id: grid
            columns: root.cols
            spacing: 22

            Repeater {
                model: root.count

                Item {
                    id: cell
                    required property int index
                    readonly property int wid: index + 1
                    readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wid) ?? null
                    readonly property var wins: (ws?.toplevels?.values ?? [])
                    readonly property bool current: Hyprland.focusedWorkspace?.id === wid
                    readonly property bool selected: root.sel === wid
                    readonly property real p: Math.max(0, Math.min(1, (root.progress - index * 0.04) / 0.6))
                    property bool dropHover: false
                    width: root.cellW
                    height: root.cellH + 26
                    opacity: p
                    transform: Translate { y: (1 - cell.p) * 40 }
                    property bool dragging: false
                    z: dragging ? 10 : 0

                    Txt {
                        id: label
                        text: (cell.current ? "● " : "") + "Workspace " + cell.wid + (cell.wins.length ? "  ·  " + cell.wins.length : "")
                        font.pixelSize: 12; font.weight: Font.Bold
                        color: cell.current ? Theme.primary : Theme.subtext
                    }

                    ClippingRectangle {
                        id: screen
                        y: 22
                        width: root.cellW
                        height: root.cellH
                        radius: 16
                        color: Qt.alpha(Theme.surfaceLow, 0.85)
                        scale: cell.selected ? 1.04 : 1
                        Behavior on scale { Anim { easing.type: Theme.springy } }

                        Image {
                            anchors.fill: parent
                            source: Wallpapers.current ? Wallpapers.thumb(Wallpapers.current) : ""
                            fillMode: Image.PreserveAspectCrop
                            opacity: 0.55
                        }
                        Rectangle { anchors.fill: parent; color: cell.dropHover ? Qt.alpha(Theme.primary, 0.25) : "transparent"; Behavior on color { CAnim {} } }

                        MouseArea { anchors.fill: parent; onClicked: root.go(cell.wid); hoverEnabled: true; onEntered: root.sel = cell.wid }

                        Repeater {
                            model: cell.wins
                            Item {
                                id: w
                                required property HyprlandToplevel modelData
                                readonly property var ipc: modelData.lastIpcObject
                                readonly property real bx: ((ipc?.at?.[0] ?? 0) - root.monX) * root.s
                                readonly property real by: ((ipc?.at?.[1] ?? 0) - root.monY) * root.s
                                x: bx; y: by
                                width: Math.max(30, (ipc?.size?.[0] ?? 200) * root.s)
                                height: Math.max(20, (ipc?.size?.[1] ?? 120) * root.s)
                                z: (ipc?.floating ? 2 : 1) + (dragArea.drag.active ? 50 : 0)

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: Theme.surfaceHigh
                                    border.width: wma.containsMouse || dragArea.drag.active ? 2 : 1
                                    border.color: wma.containsMouse ? Theme.primary : Qt.alpha(Theme.outlineVariant, 0.8)
                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: root.open ? w.modelData.wayland : null
                                        live: root.open
                                    }
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: Math.min(36, parent.height * 0.4)
                                        source: Apps.icon(Apps.classOf(w.modelData), "application-x-executable")
                                        opacity: wma.containsMouse ? 1 : 0.85
                                    }
                                }
                                Txt {
                                    visible: wma.containsMouse
                                    anchors.top: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(implicitWidth, 260)
                                    text: w.modelData.title
                                    font.pixelSize: 11
                                    z: 100
                                }

                                MouseArea {
                                    id: wma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                }
                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    drag.target: w
                                    drag.threshold: 8
                                    drag.onActiveChanged: cell.dragging = drag.active
                                    onClicked: {
                                        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${w.modelData.address}" })`);
                                        Shell.close();
                                    }
                                    onPositionChanged: if (drag.active) root.markDrop(w)
                                    onReleased: {
                                        if (!drag.active && Math.abs(w.x - w.bx) < 2) return;
                                        const target = root.dropTarget(w);
                                        root.clearDrop();
                                        if (target > 0 && target !== cell.wid)
                                            Hyprland.dispatch(`hl.dsp.window.move({ window = "address:0x${w.modelData.address}", workspace = ${target}, follow = false })`);
                                        w.x = Qt.binding(() => w.bx);
                                        w.y = Qt.binding(() => w.by);
                                        Qt.callLater(() => Hyprland.refreshToplevels());
                                    }
                                }
                            }
                        }
                    }

                    // current / selected rings
                    Item { y: 22; width: root.cellW; height: root.cellH; visible: cell.current; GlowBorder { radius: 16; thickness: 3; glow: true } }
                    Rectangle {
                        y: 22; width: root.cellW; height: root.cellH; radius: 16
                        color: "transparent"; border.width: 2; border.color: Theme.tertiary
                        visible: cell.selected && !cell.current
                    }
                }
            }
        }
    }

    // ── drag & drop helpers ─────────────────────────────
    function cellAt(item) {
        const c = item.mapToItem(grid, item.width / 2, item.height / 2);
        for (let i = 0; i < grid.children.length; i++) {
            const ch = grid.children[i];
            if (ch.wid === undefined) continue;
            if (c.x >= ch.x && c.x <= ch.x + ch.width && c.y >= ch.y && c.y <= ch.y + ch.height) return ch;
        }
        return null;
    }
    function dropTarget(item) { return cellAt(item)?.wid ?? -1; }
    function markDrop(item) {
        const t = cellAt(item);
        for (const ch of grid.children) if (ch.wid !== undefined) ch.dropHover = ch === t;
    }
    function clearDrop() { for (const ch of grid.children) if (ch.wid !== undefined) ch.dropHover = false; }
}
