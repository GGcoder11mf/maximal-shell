pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services

// Audio analysis for the audio-reactive desktop.
// Reacts to ANY audio the system plays (default sink monitor) while audio-reactive mode is on
// and game mode is off. On silence everything settles and the timer stops.
//
// PERFORMANCE: cava delivers ~60 frames/s. Analysis runs per frame (cheap JS on private
// fields only). Public properties are published from ONE timer, and only when they change:
//   fast  (30 fps) : level, bass, pulse, spin, values   -> glows, thumps, dashboard ring
//   tone  (~11 fps): toneHue, toneLevel, tonePulse       -> Theme.react() (hundreds of bindings)
// Never bind widely-used things to the fast set, and never animate Viz-driven properties.
//
// INTENSITY (Shell.vizIntensity 0..1) scales every effect. MOOD (Shell.vizMood: auto | chill |
// groove | hype) shapes them; "auto" picks from ~8 s of loudness, tempo and beat density.
// The palette only SWAYS around the wallpaper colours (bounded hue offset), so the shell keeps
// matching the wallpaper, terminals and apps; Hyprland borders follow the same palette.
Singleton {
    id: root

    readonly property bool enabled: Shell.audioReactive && !Shell.gameMode
    readonly property int bars: 48

    // ── public: fast set (30 fps) ───────────────────────
    property bool active: false     // there is actually sound
    property real level: 0          // overall loudness 0..1 (× intensity)
    property real bass: 0
    property real pulse: 0          // ~1 on a beat, decays (× intensity × mood)
    property real spin: 0           // extra rotation (turns) for spinning gradients
    property var values: []         // spectrum snapshot (dashboard / analog clock)
    property real bpm: 0
    property int beats: 0
    signal beat(real strength)

    // ── public: tone set (~11 fps, quantised) — used by Theme ──
    property real toneHue: 0        // bounded hue offset in turns (0 = wallpaper palette)
    property real toneLevel: 0
    property real tonePulse: 0

    // ── mood ────────────────────────────────────────────
    property string detectedMood: "groove"
    readonly property string mood: Shell.vizMood === "auto" ? detectedMood : Shell.vizMood
    readonly property var moods: ({
        //          hue sway     colour speed   beat flash   flash decay   window borders
        chill:  { sway: 0.045, drift: 0.35, pulse: 0.55, tau: 320, hypr: "glow" },
        groove: { sway: 0.075, drift: 1.0,  pulse: 1.0,  tau: 170, hypr: "beat" },
        hype:   { sway: 0.11,  drift: 1.7,  pulse: 1.25, tau: 110, hypr: "beat" }
    })
    // current (eased) mood parameters — mood changes blend over ~2 s
    property real _sway: 0.075
    property real _drift: 1
    property real _pulseMul: 1
    property real _tau: 170
    readonly property real gain: Shell.vizIntensity * 1.6      // 0.6 (default) ≈ 1.0

    // ── private analysis state (never bound) ────────────
    property real _level: 0
    property real _bass: 0
    property real _phase: 0
    property real _beatStrength: 0
    property real _lastBeat: 0
    property real _fluxAvg: 0
    property real _lastFrame: 0
    property real _energySlow: 0
    property var _beatTimes: []
    property string _candidate: "groove"
    property real _candidateSince: 0
    property real _pendingBeat: 0
    property real _lastHypr: 0
    property real _sentHue: 0
    property bool _hyprDirty: false
    property var _prev: []
    property var _fluxHist: []      // last ~4 s of flux values (stats / tuning)
    property var _intervals: []
    property var _snapshot: []
    property int _tick: 0
    property int _frame: 0
    // profiling (ms, decaying max): analysis per frame, fast publish, palette publish
    property real _msAna: 0
    property real _msFast: 0
    property real _msTone: 0

    function avg(a, from, to) {
        let s = 0, n = 0;
        for (let i = from; i < Math.min(to, a.length); i++) { s += a[i]; n++; }
        return n ? s / n : 0;
    }
    function q(x, step) { return Math.round(x / step) * step; }

    // ── per audio frame: analysis only ──────────────────
    Connections {
        target: root.capture?.cava ?? null
        function onValuesChanged(): void {
            // PERF: analyse every other cava frame (~30 Hz) — plenty for beats, half the JS work
            if ((root._frame++ & 1) === 1) return;
            const tA = Date.now();
            const v = root.capture.cava.values;
            if (!v || v.length === 0) return;
            root._snapshot = v;

            const b = root.avg(v, 0, 6), l = root.avg(v, 0, v.length);
            root._bass = b > root._bass ? b : root._bass * 0.86 + b * 0.14;
            root._level = l > root._level ? l : root._level * 0.9 + l * 0.1;
            root._energySlow = root._energySlow * 0.995 + l * 0.005;     // ~3 s memory

            const now = Date.now();
            const dt = root._lastFrame ? Math.min(0.1, (now - root._lastFrame) / 1000) : 0;
            root._lastFrame = now;
            if (root.active) root._phase += dt * (0.03 + root._level * 0.25) * root._drift * Math.max(0.2, root.gain);

            // wake on clear sound, sleep after it has faded (hysteresis)
            if (!root.active && root._level > 0.02) { root.active = true; ticker.start(); }
            else if (root.active && root._level < 0.006) root.active = false;

            // onset: spectral flux of the kick/bass bands vs. its running average
            const p = root._prev;
            let flux = 0;
            for (let i = 0; i < 10 && i < v.length; i++) flux += Math.max(0, v[i] - (p[i] ?? 0));
            root._prev = v.slice(0, 10);
            // threshold is relative to the track itself (~top 3-10 % of frames); the floor only
            // matters in near-silence. Tuned on real music: flux peaks ~0.2, average ~0.05.
            if (root.active && flux > Math.max(0.07, root._fluxAvg * 2.0) && now - root._lastBeat > 190)
                root.onBeat(now, Math.min(1, 0.45 + flux * 2));
            root._fluxAvg = root._fluxAvg * 0.96 + flux * 0.04;
            root._msAna = Math.max(root._msAna * 0.97, Date.now() - tA);
            const fh = root._fluxHist; fh.push(flux); if (fh.length > 240) fh.shift();
        }
    }

    function onBeat(now, strength) {
        const dt = now - root._lastBeat;
        if (dt > 250 && dt < 1500) {
            const iv = [...root._intervals, dt].slice(-8);
            root._intervals = iv;
            if (iv.length >= 4) {
                const s = iv.slice().sort((a, b) => a - b);
                root.bpm = Math.round(60000 / s[Math.floor(s.length / 2)]);
            }
        }
        root._lastBeat = now;
        root._beatStrength = strength;
        root._beatTimes = [...root._beatTimes.filter(t => now - t < 8000), now];
        root.beats++;
        root.beat(strength);
        root._pendingBeat = Math.max(root._pendingBeat, strength);
    }

    // ── auto mood: classify, then require 5 s of agreement before switching ──
    function classify(now) {
        const density = root._beatTimes.filter(t => now - t < 8000).length;   // beats per 8 s
        const e = root._energySlow, bpm = root.bpm;
        if (e > 0.3 && (bpm >= 118 || density >= 15)) return "hype";
        if (e < 0.14 || (bpm > 0 && bpm < 92 && density < 9)) return "chill";
        return "groove";
    }

    // ── publisher: the only place public props change ───
    Timer {
        id: ticker
        interval: 33
        repeat: true
        running: false
        onTriggered: {
            const now = Date.now();

            // mood (auto) + ease mood parameters
            if (root.active) {
                const c = root.classify(now);
                if (c !== root._candidate) { root._candidate = c; root._candidateSince = now; }
                else if (c !== root.detectedMood && now - root._candidateSince > 5000) root.detectedMood = c;
            }
            const m = root.moods[root.mood] ?? root.moods.groove;
            const ease = (cur, tgt) => cur + (tgt - cur) * 0.05;
            root._sway = ease(root._sway, m.sway);
            root._drift = ease(root._drift, m.drift);
            root._pulseMul = ease(root._pulseMul, m.pulse);
            root._tau = ease(root._tau, m.tau);

            const g = root.gain;
            const since = now - root._lastBeat;
            const pulse = Math.min(1, root._beatStrength * g * root._pulseMul) * Math.exp(-since / root._tau);
            const home = Math.round(root._phase);
            if (!root.active) {                       // silence: glide everything home
                root._level *= 0.85; root._bass *= 0.85;
                root._phase += (home - root._phase) * 0.06;
                if (Math.abs(home - root._phase) < 0.002) root._phase = home;
            }
            // bounded sway around the wallpaper hue (never wanders off the palette)
            const hue = Math.sin(root._phase * 2 * Math.PI) * root._sway * Math.min(1, g);

            const set = (k, v) => { if (Math.abs(root[k] - v) > 0.004) root[k] = v; };
            const tF = Date.now();
            set("level", root.q(Math.min(1, root._level * g), 0.01));
            set("bass", root.q(Math.min(1, root._bass * g), 0.01));
            set("pulse", pulse < 0.02 ? 0 : root.q(pulse, 0.02));
            set("spin", root._phase);
            // visualiser spectrum follows INTENSITY: gain + a curve that lifts quiet bands
            // (intensity 0 -> tame/linear, 0.6 -> ~1.7x with lifted mids, 1 -> ~2.4x and very lively)
            if (root.active) {
                const it = Shell.vizIntensity;
                const vg = 0.6 + it * 1.8, ex = 1 - it * 0.45;
                root.values = root._snapshot.map(x => Math.min(1, Math.pow(Math.max(0, x), ex) * vg));
            }
            else if (root.values.length) root.values = [];

            root._msFast = Math.max(root._msFast * 0.97, Date.now() - tF);
            // tone set for the palette at ~7.5 fps (re-colours the WHOLE shell, so keep it rare)
            if (++root._tick % 4 === 0) {
                const tT = Date.now();
                if (Math.abs(root.toneHue - hue) > 0.004) root.toneHue = root.q(hue, 0.004);
                set("toneLevel", root.q(Math.min(1, root._level * g), 0.03));
                set("tonePulse", pulse < 0.05 ? 0 : root.q(pulse, 0.05));
                root._msTone = Math.max(root._msTone * 0.9, Date.now() - tT);
            }

            // Hyprland: keep window borders on the SAME palette as the shell (≤ 4 updates/s),
            // plus a beat flare when the mood allows it
            if (Shell.beatBorders && root.active && now - root._lastHypr > 250) {
                const flare = m.hypr === "beat" && root._pendingBeat > 0 ? Math.min(1, root._pendingBeat * g) : 0;
                if (flare > 0 || Math.abs(root.toneHue - root._sentHue) > 0.006) root.pushHypr(now, flare);
                root._pendingBeat = 0;
            }

            // fully settled -> stop ticking (zero cost on silence)
            if (!root.active && root._phase === home && pulse < 0.02 && root._level < 0.002) {
                root.level = 0; root.bass = 0; root.pulse = 0; root.spin = home;
                root.toneHue = 0; root.toneLevel = 0; root.tonePulse = 0;
                ticker.stop();
                if (root._hyprDirty) {
                    root._hyprDirty = false;
                    Quickshell.execDetached(["hyprctl", "eval", `dofile("${Theme.rice}/theme.lua")`]);
                }
            }
        }
    }

    function pushHypr(now, flare) {
        root._lastHypr = now;
        root._sentHue = root.toneHue;
        root._hyprDirty = true;
        const hx = c => c.toString().slice(1, 7);
        Quickshell.execDetached(["hyprctl", "eval",
            `MAXI.modes.beat(${flare.toFixed(2)}, "${hx(Theme.primary)}", "${hx(Theme.tertiary)}", "${hx(Theme.magenta)}", "${hx(Theme.cyan)}", ${Math.min(1, root.gain).toFixed(2)})`]);
    }

    onEnabledChanged: {
        syncCapture();
        if (!enabled) { active = false; _level = 0; _bass = 0; _beatStrength = 0; ticker.start(); }
    }

    // ── capture: created fresh when enabled, destroyed when disabled ──
    // (attaching a ServiceRef to an already-existing provider later doesn't reliably start
    //  PipeWire capture — so the provider + its ref live and die together)
    property QtObject capture: null
    Component {
        id: captureComp
        QtObject {
            property CavaProvider cava: CavaProvider { bars: root.bars }
            property ServiceRef ref: ServiceRef { service: cava }
        }
    }
    function syncCapture() {
        if (root.enabled && !root.capture) root.capture = captureComp.createObject(root);
        else if (!root.enabled && root.capture) { root.capture.destroy(); root.capture = null; }
    }
    Component.onCompleted: syncCapture()

    // debugging: qs -p <shell> ipc call viz stats
    IpcHandler {
        target: "viz"
        function stats(): string {
            const fs = root._fluxHist.slice().sort((a, b) => a - b);
            const pc = x => (fs[Math.floor(x * (fs.length - 1))] ?? 0).toFixed(3);
            return `ms ana=${root._msAna.toFixed(1)} fast=${root._msFast.toFixed(1)} tone=${root._msTone.toFixed(1)} slot=${Theme._msSlot.toFixed(1)} | flux p50=${pc(0.5)} p90=${pc(0.9)} p97=${pc(0.97)} max=${pc(1)} avg=${root._fluxAvg.toFixed(3)} n=${fs.length} | enabled=${root.enabled} capturing=${root.capture !== null} active=${root.active} ticking=${ticker.running} level=${root.level.toFixed(2)} pulse=${root.pulse.toFixed(2)} beats=${root.beats} bpm=${root.bpm} mood=${root.mood} (auto→${root.detectedMood}) energy=${root._energySlow.toFixed(2)} hue=${root.toneHue.toFixed(3)} gain=${root.gain.toFixed(2)} primary=${Theme.primary} base=${Theme.basePrimary}`;
        }
    }
}
