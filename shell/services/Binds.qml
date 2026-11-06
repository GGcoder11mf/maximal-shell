pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reads `hyprctl binds -j` and groups described binds by "Category › Description".
Singleton {
    id: root

    property var categories: []      // [{ name, binds: [{ keys: [..], desc }] }]
    property var submaps: ({})       // { submapName: [{ keys, desc }] }

    readonly property var modNames: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]
    readonly property var keyNames: ({
        "SUPER_L": "Super", "mouse:272": "LMB", "mouse:273": "RMB", "mouse_down": "Scroll ↓", "mouse_up": "Scroll ↑",
        "left": "←", "right": "→", "up": "↑", "down": "↓", "Return": "Enter", "Slash": "/", "Comma": ",",
        "Period": ".", "Minus": "−", "Equal": "=", "grave": "`", "Semicolon": ";", "Backslash": "\\",
        "Page_Up": "PgUp", "Page_Down": "PgDn", "Escape": "Esc", "Print": "PrtSc", "Backspace": "⌫", "Space": "Space",
        "XF86AudioRaiseVolume": "Vol +", "XF86AudioLowerVolume": "Vol −", "XF86AudioMute": "Mute",
        "XF86AudioMicMute": "Mic mute", "XF86AudioPlay": "Play", "XF86AudioPause": "Pause",
        "XF86AudioNext": "Next", "XF86AudioPrev": "Prev", "XF86MonBrightnessUp": "Bright +", "XF86MonBrightnessDown": "Bright −"
    })

    function keysOf(b): var {
        const out = [];
        for (const [bit, name] of modNames) if (b.modmask & bit) out.push(name);
        const k = keyNames[b.key] ?? (b.key.length === 1 ? b.key.toUpperCase() : b.key);
        if (!(k === "Super" && out.includes("Super"))) out.push(k);
        return out;
    }

    function refresh(): void { proc.running = true; }

    Process {
        id: proc
        running: true
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list;
                try { list = JSON.parse(text); } catch (e) { return; }
                const cats = new Map(), subs = {}, seen = new Set();
                for (const b of list) {
                    if (!b.description) continue;
                    const entry = { keys: root.keysOf(b), desc: b.description };
                    if (b.submap) {
                        (subs[b.submap] = subs[b.submap] ?? []).push(entry);
                        continue;
                    }
                    const parts = b.description.split(" › ");
                    const cat = parts.length > 1 ? parts[0] : "Other";
                    entry.desc = parts.length > 1 ? parts.slice(1).join(" › ") : b.description;
                    const sig = cat + entry.desc;
                    // collapse "Go to 1..10" style series into one row
                    const series = entry.desc.match(/^(.*\D)(\d+)$/);
                    if (series && cat === "Workspaces") {
                        const key = cat + series[1];
                        if (seen.has(key)) continue;
                        seen.add(key);
                        entry.desc = series[1] + "1…10";
                        entry.keys = entry.keys.slice(0, -1).concat(["1…0"]);
                    } else if (seen.has(sig + entry.keys.join("+"))) continue;
                    seen.add(sig + entry.keys.join("+"));
                    if (!cats.has(cat)) cats.set(cat, []);
                    cats.get(cat).push(entry);
                }
                root.categories = [...cats.entries()].map(([name, binds]) => ({ name, binds }));
                root.submaps = subs;
            }
        }
    }
}
