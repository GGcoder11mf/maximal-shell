import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.widgets

// App launcher: fuzzy search + frecency.
//   >  commands (>wallpaper opens a live-preview wallpaper grid, >scheme picks a palette style…)
//   =  calculator (qalc)   !  run shell command   ?  web search
Overlay {
    id: root
    name: "launcher"
    dim: 0.3

    property string query: ""
    readonly property string mode: query.startsWith("=") ? "calc" : query.startsWith(">") ? "cmd" : query.startsWith("!") ? "run" : query.startsWith("?") ? "web" : "apps"
    readonly property string arg: mode === "apps" ? query.trim() : query.slice(1).trim()
    property string calcResult: ""
    property var counts: ({})

    // command-mode parsing: ">word rest"
    readonly property string cmdWord: mode === "cmd" ? query.slice(1).replace(/^\s+/, "").split(/\s+/)[0].toLowerCase() : ""
    readonly property string cmdArg: { const t = query.slice(1).replace(/^\s+/, ""); const i = t.search(/\s/); return i < 0 ? "" : t.slice(i).trim(); }
    readonly property var cmd: commands.find(c => c.name === cmdWord || (c.alias ?? []).includes(cmdWord)) ?? null
    readonly property string sub: mode === "cmd" && cmd?.sub && /\s/.test(query.slice(1).replace(/^\s+/, "")) ? cmd.sub : ""

    onOpened: { query = ""; input.text = ""; list.currentIndex = 0; input.forceActiveFocus(); }
    onOpenChanged: if (!open) Wallpapers.preview = ""
    onSubChanged: { if (sub !== "wallpaper") Wallpapers.preview = ""; else { Wallpapers.refresh(); grid.currentIndex = Math.max(0, wallResults.indexOf(Wallpapers.current)); } }

    function sh(cmdline, delay) { Quickshell.execDetached(["sh", "-c", (delay ? "sleep " + delay + "; " : "") + cmdline]); }
    function lua(code) { Shell.hypr(code); }
    function onoff(b) { return b ? "on → off" : "off → on"; }

    readonly property var commands: [
        { name: "wallpaper", alias: ["wall", "wp", "bg"], icon: "wallpaper", desc: "Browse wallpapers with live preview · Enter applies + re-themes", sub: "wallpaper" },
        { name: "random", alias: ["shuffle"], icon: "shuffle", desc: "Random wallpaper + new palette", run: () => sh(Theme.scripts + "wallpaper.sh --random") },
        { name: "scheme", alias: ["style", "variant", "palette"], icon: "palette", desc: "Palette style — now: " + Wallpapers.scheme.replace("scheme-", ""), sub: "scheme" },
        { name: "lock", icon: "lock", desc: "Lock the screen", run: () => sh("hyprlock -c " + Theme.rice + "/hyprlock.conf", 0.3) },
        { name: "power", alias: ["shutdown", "reboot", "logout"], icon: "power_settings_new", desc: "Power menu", panel: "power" },
        { name: "dashboard", alias: ["dash"], icon: "space_dashboard", desc: "Clock, weather, media, calendar, system", panel: "dashboard" },
        { name: "control", alias: ["settings", "cc"], icon: "tune", desc: "Quick toggles, sliders, notifications", panel: "control" },
        { name: "keybinds", alias: ["keys", "binds", "cheatsheet", "help"], icon: "keyboard", desc: "Every shortcut, searchable", panel: "cheatsheet" },
        { name: "overview", alias: ["windows", "expo"], icon: "grid_view", desc: "All workspaces with live previews", panel: "overview" },
        { name: "pictures", alias: ["gallery"], icon: "photo_library", desc: "Wallpaper cover-flow picker", panel: "wallpapers" },
        { name: "gamemode", alias: ["game"], icon: "sports_esports", desc: "Game mode " + onoff(Shell.gameMode), run: () => lua("MAXI.modes.toggle_game()") },
        { name: "nightlight", alias: ["night"], icon: "nightlight", desc: "Warm screen filter " + onoff(Shell.shader === "nightlight"), run: () => lua("MAXI.modes.toggle_nightlight()") },
        { name: "effect", alias: ["shader", "crt", "vibrance"], icon: "auto_awesome", desc: "Cycle screen effect — now: " + (Shell.shader || "off"), run: () => lua("MAXI.modes.cycle_shader()"), stay: true },
        { name: "timer", alias: ["countdown", "t"], icon: "timer", desc: root.cmdArg && Timers.parse(root.cmdArg) > 0 ? "Start a " + Timers.fmt(Timers.parse(root.cmdArg)) + " timer  ↵" : "Countdown in the bar — e.g. >timer 25m · 1h30m · 90s · 10:00", run: a => Timers.start(Timers.parse(a || "5m"), "Timer") },
        { name: "pomodoro", alias: ["focus", "pomo"], icon: "self_improvement", desc: "25 min focus timer", run: () => Timers.start(25 * 60, "Focus") },
        { name: "break", alias: ["rest"], icon: "local_cafe", desc: "5 min break timer", run: () => Timers.start(5 * 60, "Break") },
        { name: "stoptimer", alias: ["canceltimer"], icon: "timer_off", desc: Timers.active ? "Cancel " + Timers.label + " (" + Timers.fmt(Timers.remaining) + " left)" : "No timer running", run: () => Timers.cancel() },
        { name: "wsosd", alias: ["workspaceosd"], icon: "filter_9_plus", desc: "Big workspace number on switch " + onoff(Shell.wsOsd), run: () => { Shell.wsOsd = !Shell.wsOsd; } },
        { name: "stage", alias: ["music", "nowplaying", "np"], icon: "theater_comedy", desc: "Music Stage — full-screen now playing, lyrics, visualiser", panel: "stage" },
        { name: "albumcolors", alias: ["albumcolours", "artcolors", "cover"], icon: "palette", desc: "Theme the rice from the album art " + onoff(Shell.albumColors), run: () => { Shell.albumColors = !Shell.albumColors; } },
        { name: "autostage", alias: ["idle"], icon: "bedtime", desc: "Open the stage when idle while music plays " + onoff(Shell.stageAuto), run: () => { Shell.stageAuto = !Shell.stageAuto; } },
        { name: "clock", alias: ["analog", "digital", "watch"], icon: "nest_clock_farsight_analog", desc: "Desktop clock → " + (Shell.analogClock ? "digital" : "analog") + " (animated morph)", run: () => { Shell.analogClock = !Shell.analogClock; } },
        { name: "mood", alias: ["vibe"], icon: "local_fire_department", desc: "Music mood: " + Shell.vizMood + (Shell.vizMood === "auto" ? " (" + Viz.detectedMood + ")" : "") + " → " + ({ auto: "chill", chill: "groove", groove: "hype", hype: "auto" })[Shell.vizMood], run: () => { Shell.vizMood = ({ auto: "chill", chill: "groove", groove: "hype", hype: "auto" })[Shell.vizMood] ?? "auto"; }, stay: true },
        { name: "reactive", alias: ["audio", "visualizer", "music"], icon: "graphic_eq", desc: "Audio-reactive desktop " + onoff(Shell.audioReactive), run: () => { Shell.audioReactive = !Shell.audioReactive; } },
        { name: "beatborders", alias: ["beat"], icon: "border_outer", desc: "Window borders flash on beats " + onoff(Shell.beatBorders), run: () => { Shell.beatBorders = !Shell.beatBorders; } },
        { name: "zen", icon: "self_improvement", desc: "No bar, no gaps, no borders", run: () => lua("MAXI.modes.toggle_zen()") },
        { name: "layout", icon: "view_quilt", desc: "Cycle dwindle → master → scrolling", run: () => lua("MAXI.modes.cycle_layout()"), stay: true },
        { name: "gaps", icon: "padding", desc: "Cycle gap size", run: () => lua("MAXI.modes.cycle_gaps(1)()"), stay: true },
        { name: "transparency", alias: ["opacity", "glass"], icon: "opacity", desc: "Glass windows on/off", run: () => lua("MAXI.modes.toggle_opacity()") },
        { name: "dnd", alias: ["silence"], icon: "do_not_disturb_on", desc: "Do not disturb " + onoff(Shell.dnd), run: () => { Shell.dnd = !Shell.dnd; } },
        { name: "caffeine", alias: ["awake"], icon: "coffee", desc: "Keep screen awake " + onoff(Shell.caffeine), run: () => { Shell.caffeine = !Shell.caffeine; } },
        { name: "screenshot", alias: ["ss", "shot"], icon: "screenshot_region", desc: "Region screenshot (frozen screen)", run: () => sh(Theme.scripts + "screenshot.sh freeze", 0.4) },
        { name: "annotate", alias: ["edit"], icon: "draw", desc: "Screenshot a region and draw on it", run: () => sh(Theme.scripts + "screenshot.sh edit", 0.4) },
        { name: "ocr", alias: ["text"], icon: "document_scanner", desc: "Copy text from a screen region", run: () => sh(Theme.scripts + "screenshot.sh ocr", 0.4) },
        { name: "record", alias: ["rec"], icon: "radio_button_checked", desc: Shell.recording ? "Stop recording" : "Record the screen", run: () => sh(Theme.scripts + "record.sh", 0.4) },
        { name: "colorpicker", alias: ["color", "picker"], icon: "colorize", desc: "Pick a colour → clipboard", run: () => sh(Theme.scripts + "colorpick.sh", 0.3) },
        { name: "clipboard", alias: ["clip"], icon: "content_paste", desc: "Clipboard history", run: () => sh(Theme.scripts + "clipboard.sh", 0.2) },
        { name: "emoji", icon: "mood", desc: "Emoji picker", run: () => sh(Theme.scripts + "emoji.sh", 0.2) },
        { name: "reload", alias: ["restart"], icon: "refresh", desc: "Reload the shell", run: () => Quickshell.reload(false) },
        { name: "hyprland", alias: ["hypr"], icon: "deployed_code", desc: "Reload Hyprland config", run: () => sh("hyprctl reload") }
    ]

    readonly property var schemes: [
        ["scheme-vibrant", "Vibrant", "Punchy, saturated accents"], ["scheme-expressive", "Expressive", "Playful hue shifts"],
        ["scheme-fruit-salad", "Fruit salad", "Bold, multi-hue"], ["scheme-rainbow", "Rainbow", "Full-spectrum accents"],
        ["scheme-tonal-spot", "Tonal", "Calm Material default"], ["scheme-content", "Content", "Closest to the image"],
        ["scheme-fidelity", "Fidelity", "Faithful to source colour"], ["scheme-monochrome", "Monochrome", "Greyscale"]
    ]

    readonly property var wallResults: {
        const q = cmdArg.toLowerCase();
        return Wallpapers.list.filter(w => !q || w.split("/").pop().toLowerCase().includes(q));
    }

    function matchCmd(c, q) {
        if (!q) return 1;
        const names = [c.name, ...(c.alias ?? [])];
        if (names.some(n => n.startsWith(q))) return 3;
        if (names.some(n => n.includes(q))) return 2;
        return c.desc.toLowerCase().includes(q) ? 1 : 0;
    }

    // ── frecency store ──────────────────────────────────
    FileView {
        id: store
        path: Theme.home + "/.local/state/maximal/launches.json"
        printErrors: false
        onLoaded: { try { root.counts = JSON.parse(text()); } catch (e) {} }
    }
    function bump(id) {
        const c = Object.assign({}, counts);
        c[id] = (c[id] ?? 0) + 1;
        counts = c;
        store.setText(JSON.stringify(c));
    }

    // ── scoring ─────────────────────────────────────────
    function score(e, q) {
        const n = (e.name ?? "").toLowerCase();
        if (!q) return 0;
        if (n === q) return 1000;
        if (n.startsWith(q)) return 800 - n.length;
        if (n.split(/[\s\-_.]/).some(w => w.startsWith(q))) return 600 - n.length;
        if (n.includes(q)) return 400 - n.indexOf(q);
        const extra = [e.genericName, e.comment, ...(e.keywords ?? []), e.id].join(" ").toLowerCase();
        if (extra.includes(q)) return 250;
        let i = 0;
        for (const ch of n) if (ch === q[i]) i++;
        return i === q.length ? 100 - n.length : -1;
    }

    readonly property var apps: {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const q = arg.toLowerCase();
        const freq = e => (counts[e.id] ?? 0);
        if (!q) return all.slice().sort((a, b) => freq(b) - freq(a) || a.name.localeCompare(b.name)).slice(0, 60);
        return all.map(e => ({ e, s: score(e, q) + Math.min(150, freq(e) * 15) }))
                  .filter(x => x.s >= 0).sort((a, b) => b.s - a.s).slice(0, 40).map(x => x.e);
    }

    readonly property var results: {
        if (mode === "calc") return [{ kind: "calc", name: calcResult || "…", desc: arg ? arg + "  ·  Enter to copy" : "Type an expression — units, currency, maths", icon: "calculate" }];
        if (mode === "run") return [{ kind: "run", name: arg || "Type a shell command", desc: "Enter: run  ·  Shift+Enter: run in terminal", icon: "terminal" }];
        if (sub === "scheme") return schemes.filter(x => !cmdArg || x[1].toLowerCase().includes(cmdArg.toLowerCase()))
            .map(x => ({ kind: "scheme", id: x[0], name: x[1] + (x[0] === Wallpapers.scheme ? "   ✓ current" : ""), desc: x[2], icon: "palette" }));
        if (sub === "wallpaper") return [];
        if (mode === "cmd") return commands.map((c, i) => ({ c, i, m: matchCmd(c, cmdWord) })).filter(x => x.m > 0).sort((a, b) => b.m - a.m || a.i - b.i)
            .map(x => ({ kind: "cmd", cmd: x.c, name: ">" + x.c.name, desc: x.c.desc, icon: x.c.icon }));
        if (mode === "web") return [{ kind: "web", name: arg || "Search the web", desc: "DuckDuckGo in Zen", icon: "travel_explore" }];
        return apps.map(e => ({ kind: "app", entry: e, name: e.name, desc: e.genericName || e.comment || "", iconName: e.icon, id: e.id }));
    }

    function activate(r, shift) {
        if (!r) return;
        if (r.kind === "cmd") {
            const c = r.cmd;
            if (c.sub) { input.text = ">" + c.name + " "; return; }          // enter the sub-picker
            if (c.panel) { Shell.open(c.panel); return; }
            if (!c.stay) Shell.close();
            c.run(root.cmdArg);            // text after the command, e.g. ">timer 25m" -> "25m"
            return;
        }
        if (r.kind === "scheme") { Wallpapers.setScheme(r.id); Toaster.show("Palette style", r.name.replace(/\s+✓.*/, ""), "palette"); Shell.close(); return; }
        if (r.kind === "app") { bump(r.id); r.entry.execute(); }
        else if (r.kind === "calc" && calcResult) Quickshell.execDetached(["wl-copy", calcResult.replace(/^.*=\s*/, "")]);
        else if (r.kind === "run" && arg) {
            if (shift) Quickshell.execDetached(["foot", "-c", Theme.rice + "/foot.ini", "sh", "-c", arg + "; exec $SHELL"]);
            else Quickshell.execDetached(["sh", "-c", arg]);
        } else if (r.kind === "web" && arg) Quickshell.execDetached(["zen-browser", "https://duckduckgo.com/?q=" + encodeURIComponent(arg)]);
        Shell.close();
    }
    function applyWall(i) {
        const w = wallResults[i];
        if (!w) return;
        Wallpapers.set(w);
        Toaster.show("Wallpaper", w.split("/").pop(), "wallpaper");
        Shell.close();
    }

    // live preview of the highlighted wallpaper (debounced so fast scrolling stays smooth)
    Timer {
        id: previewTimer
        interval: 170
        onTriggered: if (root.sub === "wallpaper" && root.open) Wallpapers.preview = root.wallResults[grid.currentIndex] ?? ""
    }

    Timer { id: calcDebounce; interval: 120; onTriggered: if (root.mode === "calc" && root.arg) calc.running = true }
    onArgChanged: if (mode === "calc") calcDebounce.restart()
    Process {
        id: calc
        command: ["qalc", "-t", root.arg]
        stdout: StdioCollector { onStreamFinished: root.calcResult = text.trim().split("\n").pop() }
    }

    // ── card ────────────────────────────────────────────
    Glass {
        id: card
        width: 720
        height: 620
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.16 + (1 - root.progress) * 60
        opacity: root.progress
        scale: 0.92 + 0.08 * root.progress
        radius: Theme.radiusLg
        fancy: true
        glow: true
        period: 6000
        color: Qt.alpha(Theme.surface, 0.82)

        MouseArea { anchors.fill: parent }   // swallow backdrop clicks

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            // header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                GradientText { text: root.sub === "wallpaper" ? "wallpapers" : root.sub === "scheme" ? "palette" : root.mode === "cmd" ? "commands" : "launch"; font.pixelSize: 30; font.weight: Font.Black; font.letterSpacing: -1 }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: [[">", "cmd"], ["=", "calc"], ["!", "run"], ["?", "web"]]
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.mode === modelData[1]
                        width: hint.implicitWidth + 20; height: 26; radius: 13
                        color: on ? Theme.primary : Theme.chip
                        Behavior on color { CAnim {} }
                        Txt { id: hint; anchors.centerIn: parent; text: parent.modelData[0] + "  " + parent.modelData[1]; font.family: Theme.mono; font.pixelSize: 11; font.weight: Font.Bold; color: parent.on ? Theme.onPrimary : Theme.subtext }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { input.text = parent.modelData[0]; input.forceActiveFocus(); } }
                    }
                }
            }

            // search field
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                radius: 29
                color: Theme.chip
                GlowBorder { radius: 29; thickness: input.activeFocus ? 2.5 : 1; period: 3500 }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12
                    Icon {
                        icon: root.sub === "wallpaper" ? "wallpaper" : root.sub === "scheme" ? "palette" : root.mode === "cmd" ? "chevron_right" : root.mode === "calc" ? "calculate" : root.mode === "run" ? "terminal" : root.mode === "web" ? "travel_explore" : "search"
                        size: 24; fill: 1; color: Theme.primary
                    }
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 19
                        selectionColor: Theme.primaryContainer
                        selectedTextColor: Theme.onPrimaryContainer
                        cursorDelegate: Rectangle {
                            width: 2; color: Theme.primary
                            SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                        }
                        onTextChanged: { root.query = text; list.currentIndex = 0; }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !input.text
                            text: "Search apps  ·  >commands  =calc  !run  ?web"
                            color: Qt.alpha(Theme.subtext, 0.6)
                            font.pixelSize: 17
                        }
                        Keys.onPressed: e => {
                            if (root.sub === "wallpaper") {
                                if (e.key === Qt.Key_Right || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) grid.moveCurrentIndexRight();
                                else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) grid.moveCurrentIndexLeft();
                                else if (e.key === Qt.Key_Down) grid.moveCurrentIndexDown();
                                else if (e.key === Qt.Key_Up) grid.moveCurrentIndexUp();
                                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.applyWall(grid.currentIndex);
                                else if (e.key === Qt.Key_Escape) Shell.close();
                                else return;
                                e.accepted = true;
                                return;
                            }
                            // Tab on a command autocompletes it (and opens sub-pickers)
                            if (e.key === Qt.Key_Tab && root.mode === "cmd" && !root.sub && root.results[list.currentIndex]?.kind === "cmd") {
                                const c = root.results[list.currentIndex].cmd;
                                input.text = ">" + c.name + (c.sub ? " " : "");
                                e.accepted = true;
                                return;
                            }
                            if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)) || (e.key === Qt.Key_J && e.modifiers & Qt.ControlModifier)) { list.incrementCurrentIndex(); e.accepted = true; }
                            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (e.key === Qt.Key_K && e.modifiers & Qt.ControlModifier)) { list.decrementCurrentIndex(); e.accepted = true; }
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.activate(root.results[list.currentIndex], e.modifiers & Qt.ShiftModifier); e.accepted = true; }
                            else if (e.key === Qt.Key_Escape) { Shell.close(); e.accepted = true; }
                        }
                    }
                    Txt { text: root.sub === "wallpaper" ? (grid.currentIndex + 1) + " / " + root.wallResults.length : root.results.length + (root.mode === "apps" ? " apps" : root.mode === "cmd" && !root.sub ? " cmds" : ""); font.family: Theme.mono; font.pixelSize: 11; color: Theme.subtext }
                }
            }

            // results
            ListView {
                id: list
                visible: root.sub !== "wallpaper"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: ScriptModel { values: root.results }
                highlightMoveDuration: Theme.normal
                highlightResizeDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                highlight: Rectangle {
                    radius: 18
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.alpha(Theme.primary, 0.32) }
                        GradientStop { position: 1; color: Qt.alpha(Theme.tertiary, 0.08) }
                    }
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.5)
                    Rectangle { width: 4; height: parent.height * 0.5; radius: 2; anchors.verticalCenter: parent.verticalCenter; x: 6; color: Theme.primary }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool sel: ListView.isCurrentItem
                    width: list.width
                    height: row.modelData.kind === "app" ? 58 : 84

                    opacity: 0
                    Component.onCompleted: enter.start()
                    ParallelAnimation {
                        id: enter
                        SequentialAnimation { PauseAnimation { duration: Math.max(0, Math.min(row.index, 10)) * 22 } Anim { target: row; property: "opacity"; to: 1; duration: Theme.normal } }
                        SequentialAnimation { PauseAnimation { duration: Math.max(0, Math.min(row.index, 10)) * 22 } Anim { target: content; property: "x"; from: 40; to: 0; duration: Theme.slow; easing.type: Theme.springy } }
                    }

                    RowLayout {
                        id: content
                        width: parent.width
                        height: parent.height
                        spacing: 14
                        Item { Layout.preferredWidth: 6 }
                        Item {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            scale: row.sel ? 1.15 : 1
                            Behavior on scale { Anim { easing.type: Theme.springy } }
                            IconImage {
                                anchors.fill: parent
                                visible: row.modelData.kind === "app"
                                source: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.iconName ?? "", "application-x-executable") : ""
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: row.modelData.kind !== "app"
                                radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: Theme.primary }
                                    GradientStop { position: 1; color: Theme.tertiary }
                                }
                                Icon { anchors.centerIn: parent; icon: row.modelData.icon ?? ""; size: 22; fill: 1; color: Theme.onPrimary }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Txt {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                font.pixelSize: row.modelData.kind === "calc" ? 26 : 15
                                font.weight: row.sel ? Font.Bold : Font.Medium
                                font.family: row.modelData.kind === "calc" ? Theme.mono : Theme.font
                                color: row.sel ? Theme.text : Qt.alpha(Theme.text, 0.85)
                            }
                            Txt {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.desc
                                font.pixelSize: 12
                                color: Theme.subtext
                            }
                        }
                        Txt {
                            visible: row.sel
                            text: "↵"
                            font.pixelSize: 18
                            color: Theme.primary
                            Layout.rightMargin: 14
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: root.activate(row.modelData, false)
                    }
                }
            }

            // ── >wallpaper grid ─────────────────────────
            GridView {
                id: grid
                visible: root.sub === "wallpaper"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / 3)
                cellHeight: Math.floor(cellWidth * 0.62)
                model: ScriptModel { values: root.wallResults }
                highlightMoveDuration: Theme.normal
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: previewTimer.restart()
                onVisibleChanged: if (visible) previewTimer.restart()

                delegate: Item {
                    id: tile
                    required property string modelData
                    required property int index
                    readonly property bool sel: GridView.isCurrentItem
                    readonly property bool applied: modelData === Wallpapers.current
                    width: grid.cellWidth
                    height: grid.cellHeight

                    opacity: 0
                    scale: 0.8
                    Component.onCompleted: pop.start()
                    ParallelAnimation {
                        id: pop
                        SequentialAnimation { PauseAnimation { duration: Math.max(0, Math.min(tile.index, 12)) * 30 } Anim { target: tile; property: "opacity"; to: 1 } }
                        SequentialAnimation { PauseAnimation { duration: Math.max(0, Math.min(tile.index, 12)) * 30 } Anim { target: tile; property: "scale"; to: 1; duration: Theme.slow; easing.type: Theme.springy } }
                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 7
                        scale: tile.sel ? 1.0 : 0.93
                        Behavior on scale { Anim { duration: Theme.normal; easing.type: Theme.springy } }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 18
                            color: Theme.chip
                            Image {
                                anchors.fill: parent
                                source: Wallpapers.thumb(tile.modelData)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 320
                                onStatusChanged: if (status === Image.Error) source = "file://" + tile.modelData
                                opacity: tile.sel ? 1 : 0.7
                                Behavior on opacity { Anim {} }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 34
                                visible: tile.sel || tile.applied
                                gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha("black", 0.7) } }
                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 4
                                    spacing: 5
                                    Icon { visible: tile.applied; icon: "check_circle"; size: 14; fill: 1; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                                    Txt { text: tile.modelData.split("/").pop(); font.pixelSize: 10; font.family: Theme.mono; color: "white"; width: Math.min(implicitWidth, tile.width - 50) }
                                }
                            }
                        }
                        GlowBorder { visible: tile.sel; radius: 18; thickness: 3; glow: true; period: 2500 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: grid.currentIndex = tile.index
                        onClicked: root.applyWall(tile.index)
                    }
                }

                Txt {
                    anchors.centerIn: parent
                    visible: root.wallResults.length === 0
                    text: "No wallpapers match “" + root.cmdArg + "”"
                    color: Theme.subtext
                }
            }

            // footer hint for the pickers
            Txt {
                Layout.fillWidth: true
                visible: root.sub !== "" || (root.mode === "cmd")
                horizontalAlignment: Text.AlignHCenter
                text: root.sub === "wallpaper" ? "arrows browse (live preview)  ·  type to filter  ·  ↵ apply + re-theme  ·  esc revert"
                    : root.sub === "scheme" ? "↵ apply palette style to the current wallpaper"
                    : "tab completes  ·  ↵ runs  ·  try  >wallpaper  >scheme  >gamemode  >ocr"
                font.family: Theme.mono
                font.pixelSize: 11
                color: Qt.alpha(Theme.subtext, 0.75)
            }
        }
    }
}
