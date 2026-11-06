pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Desktop widgets: catalogue, placed instances, edit mode, persistence.
// Layout + per-widget data live in ~/.local/state/maximal/widgets.json
//   { "items": [ { "uid": 3, "type": "todo", "x": 1460, "y": 90, "scale": 1, "data": {…} } ] }
// Edit mode: right-click the empty desktop · Super+F12 · >widgets
Singleton {
    id: root

    readonly property var catalog: [
        { type: "sysmon",   name: "System monitor", icon: "monitoring",       desc: "CPU, RAM, temperature rings + CPU graph" },
        { type: "weather",  name: "Weather",        icon: "partly_cloudy_day", desc: "Now + the next hours" },
        { type: "calendar", name: "Calendar",       icon: "calendar_month",   desc: "Month view, scroll to change month" },
        { type: "notes",    name: "Sticky note",    icon: "sticky_note_2",    desc: "Type anything — it's saved" },
        { type: "todo",     name: "To-do",          icon: "checklist",        desc: "Add, tick off and clear tasks" },
        { type: "apps",     name: "Quick apps",     icon: "apps",             desc: "Your most-launched apps" },
        { type: "timer",    name: "Pomodoro",       icon: "timer",            desc: "Focus timer with presets" },
        { type: "nowplaying", name: "Now playing",  icon: "album",            desc: "Album art + vinyl, progress, synced lyrics" }
    ]
    function info(type) { return catalog.find(c => c.type === type) ?? { name: type, icon: "widgets", desc: "" }; }

    property var items: []            // [{uid, type, x, y, scale, data}]
    property bool editMode: false
    property bool galleryOpen: false
    property int _nextUid: 1
    property bool _loaded: false
    property bool _npMigrated: false
    readonly property bool wantsKeyboard: items.some(i => i.type === "notes" || i.type === "todo")

    onEditModeChanged: if (!editMode) galleryOpen = false

    function add(type) {
        // drop new widgets near the screen centre, cascading so they don't stack exactly
        const n = items.length;
        const it = { uid: _nextUid++, type, x: 760 + (n % 5) * 30, y: 300 + (n % 5) * 30, scale: 1, data: {} };
        items = [...items, it];
        galleryOpen = false;
        save();
        return it.uid;
    }
    function remove(uid) { items = items.filter(i => i.uid !== uid); save(); }
    function update(uid, patch) {
        items = items.map(i => i.uid === uid ? Object.assign({}, i, patch) : i);
        save();
    }
    function setData(uid, data) {
        // data changes (typing in a note) don't need to rebuild the delegates: mutate in place, then persist
        const it = items.find(i => i.uid === uid);
        if (it) { it.data = data; save(); }
    }
    function dataOf(uid) { return items.find(i => i.uid === uid)?.data ?? {}; }

    // ── persistence ─────────────────────────────────────
    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/maximal/widgets.json"
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.items = (j.items ?? []).map(i => Object.assign({ scale: 1, data: {} }, i));
                root._npMigrated = j.npMigrated ?? false;
            } catch (e) { root.items = []; }
            root._nextUid = Math.max(1, ...root.items.map(i => i.uid + 1));
            root._loaded = true;
            // one-time: the now-playing card used to be fixed at the bottom-right — keep it there as a widget
            if (!root._npMigrated) {
                root._npMigrated = true;
                if (!root.items.some(i => i.type === "nowplaying"))
                    root.items = [...root.items, { uid: root._nextUid++, type: "nowplaying", x: 1340, y: 720, scale: 1, data: {} }];
                root.save();
            }
        }
        onLoadFailed: {     // first run: a sensible starter layout (top-right column)
            root.items = [
                { uid: 1, type: "sysmon", x: 1540, y: 86, scale: 1, data: {} },
                { uid: 2, type: "todo", x: 1540, y: 330, scale: 1, data: { tasks: [{ t: "Right-click the desktop to edit widgets", d: false }] } },
                { uid: 3, type: "nowplaying", x: 1340, y: 720, scale: 1, data: {} }
            ];
            root._nextUid = 4;
            root._npMigrated = true;
            root._loaded = true;
            root.save();
        }
    }
    Timer { id: saveTimer; interval: 600; onTriggered: file.setText(JSON.stringify({ npMigrated: root._npMigrated, items: root.items }, null, 2) + "\n") }
    function save() { if (_loaded) saveTimer.restart(); }

    IpcHandler {
        target: "widgets"
        function edit(): void { root.editMode = !root.editMode; }
        function gallery(): void { root.editMode = true; root.galleryOpen = !root.galleryOpen; }
        function add(type: string): void { root.add(type); }
        function remove(uid: int): void { root.remove(uid); }
        function move(uid: int, x: int, y: int): void { root.update(uid, { x, y }); }
        function list(): string { return root.items.map(i => `${i.uid}:${i.type}@${i.x},${i.y}x${i.scale}`).join(" "); }
    }
}
