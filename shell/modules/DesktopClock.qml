import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import qs.services
import qs.widgets

// Desktop clock that MORPHS between digital and analog.
//
// The digits sit on an invisible string. During the transition the string bends with
// increasing curvature (kappa = t / R) until it closes into a circle; each character rides
// along it (rotated to the tangent), shrinks, and dissolves into the hour numeral of the slot it
// lands on. Four extra numerals grow out of the string's ends. Then 60 ticks sweep in and the
// hands grow from the centre. Reverse = the dial unwraps back into a line of digits.
// The tick ring is a radial spectrum and the face thumps on beats (audio-reactive).
//
// Slots 0..11 travel along the string. Digital text uses slots 2..9 = "H H : M M : S S".
// On the circle, slot k sits at arc length (k-6)*(2πR/12) from the bottom, i.e. numeral (12-k)%12.
Item {
    id: root
    // PERF gate: music values only flow while the desktop is visible (no windows covering it).
    property bool live: true
    readonly property real pz: live ? Viz.pulse : 0
    readonly property real lv: live ? Viz.level : 0
    readonly property real bs: live ? Viz.bass : 0
    readonly property var vals: live ? Viz.values : []
    width: 760
    height: 660

    // 0 = digital, 1 = analog
    property real t: Shell.analogClock ? 1 : 0
    readonly property real debugT: Shell.clockDebugT  // >= 0 overrides t (for snapshots)
    readonly property real tt: debugT >= 0 ? debugT : t
    Behavior on t { NumberAnimation { duration: Theme.calm ? 0 : 1700; easing.type: Easing.InOutCubic } }

    readonly property real rad: 205
    readonly property real cx: 340                    // digital line centre / dial centre (x)
    readonly property real by: height - 165           // digital baseline-centre (y) = dial bottom
    readonly property real cy: by - rad               // dial centre (y)
    // where the aura behind the clock should sit (followed by Background)
    readonly property real focusX: lerp(cx, cx, tt)
    readonly property real focusY: lerp(by - 30, cy, tt)

    function lerp(a, b, x) { return a + (b - a) * x; }
    function sstep(a, b, x) { const u = Math.max(0, Math.min(1, (x - a) / (b - a))); return u * u * (3 - 2 * u); }

    SystemClock { id: clock; precision: SystemClock.Seconds }
    readonly property string hh: Qt.formatDateTime(clock.date, "HH")
    readonly property string mm: Qt.formatDateTime(clock.date, "mm")
    readonly property string ss: Qt.formatDateTime(clock.date, "ss")
    readonly property var glyphs: ["", "", hh[0], hh[1], ":", mm[0], mm[1], ":", ss[0], ss[1], "", ""]
    readonly property var dScale: [0.3, 0.3, 1, 1, 1, 1, 1, 0.34, 0.34, 0.34, 0.3, 0.3]
    readonly property real fontPx: 168
    readonly property real numeralScale: 0.2

    FontMetrics { id: fm; font.family: Theme.font; font.weight: Font.Black; font.pixelSize: root.fontPx }
    // A Text's box includes ascent/descent, so digits sit off-centre in it. This offset moves
    // the *drawn* digit's centre onto the anchor point (keeps numerals exactly on the ring).
    readonly property real digitCentreFix: {
        const r = fm.tightBoundingRect("0");                 // relative to the baseline
        const digitMid = r.y + r.height / 2;
        const boxMid = (fm.descent - fm.ascent) / 2;
        return -(digitMid - boxMid);
    }

    // arc-length centre of each slot on the straight (digital) string, centred on slots 2..9
    readonly property var lineS: {
        const w = glyphs.map((c, i) => (c ? fm.advanceWidth(c) * 0.9 : fm.advanceWidth("0") * 0.9) * dScale[i]);
        const xs = [];
        let x = 0;
        for (let i = 0; i < 12; i++) { xs.push(x + w[i] / 2); x += w[i]; }
        const left = xs[2] - w[2] / 2, right = xs[9] + w[9] / 2;
        const mid = (left + right) / 2;
        return xs.map(v => v - mid);
    }
    readonly property real lineLeft: lineS[2] - fm.advanceWidth(glyphs[2] || "0") * 0.45

    // ── glow + beat thump on the whole clock ──────────────
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.primary
        shadowBlur: 0.9
        shadowOpacity: 0.45 + root.lv * 0.3 + root.pz * 0.35
        autoPaddingEnabled: true
    }
    transform: Scale {
        origin.x: root.cx; origin.y: root.lerp(root.by, root.cy, root.tt)
        xScale: 1 + root.pz * 0.025; yScale: xScale
    }

    // ── analog face (ring, spectrum ticks, hands) ─────────
    Item {
        id: face
        x: root.cx; y: root.cy               // origin = dial centre
        readonly property real show: root.sstep(0.5, 0.95, root.tt)
        opacity: show
        visible: opacity > 0.001
        scale: root.lerp(0.55, 1, show)

        // faint ring
        Rectangle {
            width: root.rad * 1.78; height: width; radius: width / 2
            x: -width / 2; y: -height / 2
            color: Qt.alpha(Theme.surface, 0.18)
            border.width: 2 + root.pz * 2
            border.color: Qt.alpha(Theme.primary, 0.35 + root.lv * 0.4)
        }

        // 60 ticks = radial spectrum (sweep in one after another)
        Repeater {
            model: 60
            Rectangle {
                id: tick
                required property int index
                readonly property bool major: index % 5 === 0
                readonly property int band: index < 30 ? index : 59 - index
                readonly property real v: root.vals.length ? (root.vals[Math.floor(band * Viz.bars / 30)] ?? 0) : 0
                readonly property real appear: root.sstep(0.55 + index / 60 * 0.3, 0.62 + index / 60 * 0.3, root.tt)
                width: major ? 5 : 2.5
                height: (major ? 16 : 8) + v * 44
                radius: width / 2
                x: -width / 2
                y: -root.rad * 0.86
                opacity: appear
                color: Theme.mix(major ? Theme.primary : Theme.tertiary, Theme.magenta, Math.min(1, v * 1.4))
                transform: Rotation { origin.x: tick.width / 2; origin.y: root.rad * 0.86; angle: tick.index * 6 }
            }
        }

        // hands — driven by a millisecond clock every frame (smooth sweep, no ticking).
        // Only runs while the analog face is visible.
        property real secF: 0       // seconds incl. fraction (0..60)
        property real minF: 0       // minutes incl. fraction
        property real hourF: 0      // hours (12h) incl. fraction
        readonly property real grow: root.sstep(0.72, 1.0, root.tt)
        function updateTime() {
            const d = new Date();
            face.secF = d.getSeconds() + d.getMilliseconds() / 1000;
            face.minF = d.getMinutes() + face.secF / 60;
            face.hourF = d.getHours() % 12 + face.minF / 60;
        }
        Component.onCompleted: updateTime()
        // smooth sweep only while the desktop is visible; otherwise tick once a second
        // (a per-frame repaint of the wallpaper layer would force Hyprland to re-blur windows)
        FrameAnimation {
            running: face.visible && !Theme.calm && root.live
            onTriggered: face.updateTime()
        }
        Timer {
            interval: 1000; repeat: true; triggeredOnStart: true
            running: face.visible && (Theme.calm || !root.live)
            onTriggered: face.updateTime()
        }

        // A hand is a zero-size pivot exactly at the dial centre; the bar is drawn from
        // -len up to +tail around it, so the rotation centre is precisely the hub.
        component Hand: Item {
            id: hand
            property real len
            property real tail: 0
            property real thickness: 6
            property color color: Theme.text
            property real angle
            width: 0; height: 0
            rotation: angle
            Rectangle {
                x: -hand.thickness / 2
                y: -hand.len * face.grow
                width: hand.thickness
                height: (hand.len + hand.tail) * face.grow
                radius: hand.thickness / 2
                color: hand.color
                antialiasing: true
            }
        }

        Hand {   // hour
            len: root.rad * 0.48; tail: 10; thickness: 9
            angle: face.hourF * 30
            color: Theme.text
        }
        Hand {   // minute
            len: root.rad * 0.7; tail: 12; thickness: 6
            angle: face.minF * 6
            color: Theme.primary
        }
        Hand {   // second — smooth sweep
            len: root.rad * 0.8; tail: 26; thickness: 2.5
            angle: face.secF * 6
            color: Theme.mix(Theme.magenta, Theme.cyan, root.pz)
        }
        Rectangle {   // hub
            width: 16 + root.pz * 6; height: width; radius: width / 2
            x: -width / 2; y: -height / 2
            scale: face.grow
            color: Theme.magenta
            border.width: 3
            border.color: Theme.surface
        }
    }

    // ── the travelling string: 12 slots ───────────────────
    Repeater {
        model: 12
        Item {
            id: slot
            required property int index
            readonly property real g: root.tt
            readonly property real circS: (index - 6) * (2 * Math.PI * root.rad / 12)
            readonly property real s: root.lerp(root.lineS[index] ?? 0, circS, g)
            readonly property real kappa: g / root.rad
            readonly property real theta: kappa * s
            readonly property real px: kappa < 1e-5 ? s : Math.sin(theta) / kappa
            readonly property real py: kappa < 1e-5 ? 0 : -(1 - Math.cos(theta)) / kappa
            readonly property bool extra: index < 2 || index > 9            // numeral-only slots
            readonly property string numeral: String(((12 - index) % 12) || 12)
            readonly property real dsc: root.dScale[index]
            // small digital glyphs (":ss") sit on the big digits' baseline
            readonly property real baseDrop: (1 - dsc) * root.fontPx * 0.36 * (1 - root.sstep(0, 0.5, g))

            x: root.cx + px
            y: root.by + py + baseDrop
            rotation: theta * 57.29578 * (1 - root.sstep(0.68, 1.0, g))   // follows the tangent, then turns upright
            scale: root.lerp(dsc, root.numeralScale, root.sstep(0.0, 0.85, g))
            opacity: extra ? root.sstep(0.25, 0.6, g) : 1

            readonly property color ink: Theme.mix(Theme.primary, Theme.cyan, index / 11)

            Text {   // digital character
                anchors.centerIn: parent
                text: root.glyphs[slot.index]
                opacity: 1 - root.sstep(0.32, 0.56, slot.g)
                visible: opacity > 0.001
                color: slot.ink
                font.family: Theme.font
                font.weight: Font.Black
                font.pixelSize: root.fontPx
                renderType: Text.QtRendering
            }
            Text {   // hour numeral
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.digitCentreFix
                text: slot.numeral
                opacity: root.sstep(0.44, 0.7, slot.g)
                visible: opacity > 0.001
                color: slot.index === 0 ? Theme.magenta : slot.ink
                font.family: Theme.font
                font.weight: Font.Black
                font.pixelSize: root.fontPx
                renderType: Text.QtRendering
            }
        }
    }

    // ── weekday + date glide into the face ────────────────
    Txt {
        id: weekday
        readonly property real e: root.sstep(0.15, 0.9, root.tt)
        text: Qt.formatDateTime(clock.date, "dddd").toUpperCase()
        font.pixelSize: 22
        font.weight: Font.Medium
        font.letterSpacing: root.lerp(10, 5, e)
        color: Qt.alpha(Theme.text, 0.85)
        x: root.lerp(root.cx + root.lineLeft + 6, root.cx - width / 2, e)
        y: root.lerp(root.by - root.fontPx * 0.62 - 34, root.cy - root.rad * 0.36 - height / 2, e)
        scale: root.lerp(1, 0.75, e)
    }
    Txt {
        id: date
        readonly property real e: root.sstep(0.1, 0.85, root.tt)
        text: Qt.formatDateTime(clock.date, "d MMMM yyyy") + (Weather.ok ? "   ·   " + Weather.temp + "°C  " + Weather.desc.toLowerCase() : "")
        font.pixelSize: 20
        color: Qt.alpha(Theme.text, 0.8)
        x: root.lerp(root.cx + root.lineLeft + 6, root.cx - width / 2, e)
        y: root.lerp(root.by + root.fontPx * 0.42, root.cy + root.rad * 0.3, e)
        scale: root.lerp(1, 0.68, e)
    }

    // debug: render the clock to a file (qs ipc call state set clockDebugT 0.4; … snapshot)
    Connections {
        target: Shell
        function onSnapshotClock(path: string): void { root.grabToImage(r => r.saveToFile(path)); }
    }

    // click the clock to morph
    MouseArea {
        x: root.cx - root.rad - 40
        y: root.cy - root.rad - 40
        width: Math.max(root.rad * 2 + 80, root.width - x)
        height: root.height - y
        cursorShape: Qt.PointingHandCursor
        onClicked: Shell.analogClock = !Shell.analogClock
    }
}
