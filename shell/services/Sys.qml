pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / RAM / temp / disk / network throughput / uptime, with short histories for graphs.
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real temp: 0         // °C
    property real disk: 0         // 0..1
    property string diskText: ""
    property real rx: 0           // bytes/s
    property real tx: 0
    property string uptime: ""
    property string hostname: ""
    // display name: the GECOS "full name" if set, else the login name
    property string userName: Quickshell.env("USER") ?? ""
    FileView { path: "/etc/hostname"; onLoaded: root.hostname = text().trim() }
    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector { onStreamFinished: { const n = text.trim(); if (n) root.userName = n; } }
    }
    property var cpuHistory: Array(48).fill(0)
    property var netHistory: Array(48).fill(0)

    property var _prevCpu: null
    property var _prevNet: null
    property real _prevNetTime: 0

    function bytes(b: real): string {
        if (b < 1024) return Math.round(b) + " B";
        if (b < 1048576) return (b / 1024).toFixed(b < 10240 ? 1 : 0) + " K";
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " M";
        return (b / 1073741824).toFixed(2) + " G";
    }
    function push(arr, v) { const a = arr.slice(1); a.push(v); return a; }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { stat.reload(); meminfo.reload(); netdev.reload(); up.reload(); tempProc.running = true; }
    }
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: df.running = true
    }

    FileView {
        id: stat; path: "/proc/stat"
        onLoaded: {
            const p = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = p[3] + p[4], total = p.reduce((a, b) => a + b, 0);
            if (root._prevCpu) {
                const dt = total - root._prevCpu.total, di = idle - root._prevCpu.idle;
                root.cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
                root.cpuHistory = root.push(root.cpuHistory, root.cpu);
            }
            root._prevCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo; path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = k => Number((t.match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1]);
            const total = get("MemTotal"), avail = get("MemAvailable");
            root.memTotalGb = total / 1048576;
            root.memUsedGb = (total - avail) / 1048576;
            root.mem = total > 0 ? (total - avail) / total : 0;
        }
    }

    FileView {
        id: netdev; path: "/proc/net/dev"
        onLoaded: {
            let r = 0, x = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = line.trim().split(/[:\s]+/);
                if (m.length < 10 || m[0] === "lo" || m[0].startsWith("docker") || m[0].startsWith("veth")) continue;
                r += Number(m[1]); x += Number(m[9]);
            }
            const now = Date.now();
            if (root._prevNet) {
                const dt = (now - root._prevNetTime) / 1000;
                root.rx = Math.max(0, (r - root._prevNet.r) / dt);
                root.tx = Math.max(0, (x - root._prevNet.x) / dt);
                root.netHistory = root.push(root.netHistory, root.rx);
            }
            root._prevNet = { r, x };
            root._prevNetTime = now;
        }
    }

    FileView {
        id: up; path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(Number(text().split(" ")[0]));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = (d ? d + "d " : "") + (h ? h + "h " : "") + m + "m";
        }
    }

    Process {
        id: tempProc
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in k10temp|coretemp|zenpower|cpu_thermal) cat $h/temp1_input; exit;; esac; done; cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.temp = Number(text.trim()) / 1000 || 0 }
    }

    Process {
        id: df
        command: ["df", "-P", "-B1", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[1]?.split(/\s+/);
                if (!f) return;
                root.disk = Number(f[2]) / Number(f[1]);
                root.diskText = root.bytes(Number(f[2])) + " / " + root.bytes(Number(f[1]));
            }
        }
    }
}
