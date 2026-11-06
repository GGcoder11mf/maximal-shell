pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Countdown timers / pomodoro. One active timer at a time (shown in the bar).
//   >timer 25m · >timer 1h30m · >timer 90s · >pomodoro · click the bar pill to pause, right-click to cancel
//   IPC: qs -p <shell> ipc call timer start 300 "Tea"
Singleton {
    id: root

    property bool active: false
    property bool paused: false
    property string label: ""
    property real total: 0          // seconds
    property real remaining: 0      // seconds
    readonly property real progress: total > 0 ? 1 - remaining / total : 0
    property real _endAt: 0         // ms timestamp (while running)
    signal finished(string label)

    // "25m", "1h30m", "90s", "1:30", "10" (minutes)
    function parse(text: string): real {
        const t = (text || "").trim().toLowerCase();
        if (!t) return 0;
        const colon = t.match(/^(\d+):(\d{1,2})(?::(\d{1,2}))?$/);
        if (colon) return colon[3] !== undefined ? (+colon[1] * 3600 + +colon[2] * 60 + +colon[3]) : (+colon[1] * 60 + +colon[2]);
        let secs = 0, matched = false;
        // (no String.matchAll in QML's JS engine — use exec in a loop)
        const re = /(\d+(?:\.\d+)?)\s*(h|hr|hours?|m|min|mins?|minutes?|s|sec|secs?|seconds?)/g;
        let m;
        while ((m = re.exec(t)) !== null) {
            matched = true;
            const v = parseFloat(m[1]), u = m[2][0];
            secs += u === "h" ? v * 3600 : u === "m" ? v * 60 : v;
        }
        if (matched) return secs;
        const n = parseFloat(t);
        return isNaN(n) ? 0 : n * 60;
    }
    function fmt(s: real): string {
        s = Math.max(0, Math.ceil(s));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60;
        const pad = x => (x < 10 ? "0" : "") + x;
        return h > 0 ? `${h}:${pad(m)}:${pad(r)}` : `${m}:${pad(r)}`;
    }

    function start(seconds: real, name: string): void {
        if (!(seconds > 0)) return;
        total = seconds;
        remaining = seconds;
        label = name || "Timer";
        paused = false;
        active = true;
        _endAt = Date.now() + seconds * 1000;
        tick.start();
        Toaster.show(label, "started · " + fmt(seconds), "timer");
    }
    function togglePause(): void {
        if (!active) return;
        paused = !paused;
        if (paused) tick.stop();
        else { _endAt = Date.now() + remaining * 1000; tick.start(); }
    }
    function cancel(): void {
        if (!active) return;
        tick.stop();
        active = false;
        Toaster.show(label, "cancelled", "timer_off");
    }

    Timer {
        id: tick
        interval: 250; repeat: true
        onTriggered: {
            root.remaining = Math.max(0, (root._endAt - Date.now()) / 1000);
            if (root.remaining <= 0) {
                stop();
                root.active = false;
                root.finished(root.label);
                Toaster.show(root.label, "time's up!", "alarm");
                Quickshell.execDetached(["sh", "-c",
                    "notify-send -a Timer -u critical -i alarm-symbolic \"$0\" 'Time is up' ; " +
                    "f=/usr/share/sounds/freedesktop/stereo/complete.oga; [ -f \"$f\" ] && pw-play \"$f\"", root.label]);
            }
        }
    }

    IpcHandler {
        target: "timer"
        function start(seconds: real, name: string): void { root.start(seconds, name); }
        function cancel(): void { root.cancel(); }
        function status(): string { return root.active ? `${root.label} ${root.fmt(root.remaining)} / ${root.fmt(root.total)}${root.paused ? " (paused)" : ""}` : "idle"; }
    }
}
