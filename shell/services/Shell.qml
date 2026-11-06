pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Global shell state + IPC entry point:
//   qs -p <shell> ipc call state toggle launcher
//   qs -p <shell> ipc call state set gameMode true
Singleton {
    id: root

    // Only one overlay/panel open at a time
    property string panel: ""   // launcher | dashboard | control | power | cheatsheet | wallpapers | overview
    property bool barHidden: false
    property bool gameMode: false
    property bool dnd: false
    property bool caffeine: false
    property string shader: ""
    property string submap: ""
    property bool recording: false
    property bool audioReactive: true    // desktop reacts to music (services/Viz.qml)
    property bool beatBorders: true      // window border glow flares on beats
    property bool analogClock: false     // desktop clock: digital (false) <-> analog (true), animated morph
    property real vizIntensity: 0.6      // 0..1: scales every music effect (control center slider)
    property string vizMood: "auto"      // auto | chill | groove | hype
    property bool albumColors: true      // re-theme the rice from the playing track's cover art
    property bool stageAuto: true        // open the Music Stage when idle while music plays
    property bool wsOsd: true            // big animated workspace number on switch
    property bool musicFilter: true      // only real music (not videos/shorts) drives the music features
    property real clockDebugT: -1        // >= 0 pins the clock morph (debug snapshots)
    property real audioAnchor: 1700      // screen x of the bar's volume control (audio dropdown points at it)
    function toggleAudio(item: Item): void {
        if (item) audioAnchor = item.mapToItem(null, item.width / 2, 0).x;
        toggle("audio");
    }

    // ── remembered between restarts: ~/.local/state/maximal/settings.json ──
    readonly property var _persist: ["audioReactive", "beatBorders", "analogClock", "vizIntensity", "vizMood", "dnd", "albumColors", "stageAuto", "wsOsd", "musicFilter"]
    property bool _loaded: false
    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.local/state/maximal/settings.json"
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                for (const k of root._persist) if (k in j) root[k] = j[k];
            } catch (e) {}
            root._loaded = true;
        }
        onLoadFailed: root._loaded = true
    }
    Timer {
        id: saveTimer
        interval: 500
        onTriggered: {
            const o = {};
            for (const k of root._persist) o[k] = root[k];
            settingsFile.setText(JSON.stringify(o, null, 2) + "\n");
        }
    }
    function _changed() { if (_loaded) saveTimer.restart(); }
    onAudioReactiveChanged: _changed()
    onBeatBordersChanged: _changed()
    onAnalogClockChanged: _changed()
    onVizIntensityChanged: _changed()
    onVizMoodChanged: _changed()
    onDndChanged: _changed()
    onAlbumColorsChanged: _changed()
    onStageAutoChanged: _changed()
    onWsOsdChanged: _changed()
    onMusicFilterChanged: _changed()
    signal snapshotClock(string path)
    signal switcherStep(int dir)          // Alt+Tab (Hyprland global) -> Switcher

    function toggle(p: string): void { panel = panel === p ? "" : p; }
    function open(p: string): void { panel = p; }
    function close(): void { panel = ""; }

    function hypr(lua: string): void { Quickshell.execDetached(["hyprctl", "eval", lua]); }
    function run(cmd: string): void { Quickshell.execDetached(["sh", "-c", cmd]); }

    // Submap tracking (for the hint card)
    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "submap") root.submap = event.data;
        }
    }

    // Caffeine: hypridle respects systemd idle inhibitors
    Process {
        running: root.caffeine
        command: ["systemd-inhibit", "--what=idle", "--who=maximal", "--why=Caffeine", "sleep", "infinity"]
    }

    // Recording badge
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: recCheck.running = true
    }
    Process {
        id: recCheck
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => root.recording = code === 0
    }

    IpcHandler {
        target: "state"
        function toggle(p: string): void { root.toggle(p); }
        function open(p: string): void { root.open(p); }
        function close(): void { root.close(); }
        function set(key: string, value: string): void {
            const v = value === "true" ? true : value === "false" ? false : value;
            if (key in root) root[key] = v;
        }
        function read(key: string): string { return String(root[key]); }
        function snapshot(path: string): void { root.snapshotClock(path); }
        // soft reload: if the new config fails, the running one stays alive
        function reload(): void { Quickshell.reload(false); }
    }
}
