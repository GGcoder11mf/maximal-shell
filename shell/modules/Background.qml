import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.widgets
import "desk"

// Wallpaper layer: zoom/blur crossfade between wallpapers, workspace parallax,
// a big morphing desktop clock and a now-playing card (animated only while the desktop is visible).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "maxi-bg"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        // notes / to-do widgets need typing: take keyboard focus only when clicked
        WlrLayershell.keyboardFocus: Widgets.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.surface

        readonly property HyprlandMonitor mon: Hyprland.monitorFor(modelData)
        readonly property int wsId: Math.max(1, mon?.activeWorkspace?.id ?? 1)
        // desktop actually visible (no windows on the workspace) -> desktop widgets may animate.
        // When windows cover it, desktop animations freeze (they'd only cost re-blurs).
        readonly property bool live: (mon?.activeWorkspace?.toplevels?.values?.length ?? 0) === 0
        readonly property real parallaxMax: 90

        // ── wallpaper stage ───────────────────────────────
        Item {
            id: stage
            width: win.width + win.parallaxMax
            height: win.height + win.parallaxMax * 0.3
            y: -win.parallaxMax * 0.15
            x: -((win.wsId - 1) % 10) / 9 * win.parallaxMax
            Behavior on x { Anim { duration: Theme.xslow; easing.type: Easing.OutQuint } }

            // PERF: the wallpaper is the bottom layer — every change to it makes Hyprland re-blur
            // every translucent window and the bar above it. So the wallpaper itself stays still
            // (no drift / music zoom / grading); only the workspace parallax moves it, briefly.
            // Music reactivity on the desktop is limited to the clock / now-playing / aura, and only
            // while the desktop is actually visible (win.live).

            property bool aFront: true
            property string pending: ""
            readonly property Image front: aFront ? imgA : imgB
            readonly property Image back: aFront ? imgB : imgA

            // previews (launcher ">wallpaper") use a snappier transition
            readonly property real speed: Wallpapers.preview ? 0.35 : 1

            function settle() {          // finish an in-flight reveal instantly
                if (!revealAnim.running) return;
                revealAnim.stop();
                const img = revealAnim.img;
                img.opacity = 1; img.scale = 1; img.blurAmt = 0;
                finishReveal(img);
            }
            function finishReveal(img) {
                const old = img === imgA ? imgB : imgA;
                aFront = img === imgA;
                old.opacity = 0;
                old.source = "";
                img.z = 1; old.z = 0;
            }
            function swapTo(path) {
                if (!path) return;
                settle();
                const url = "file://" + path;
                if (front.source.toString() === url) { pending = ""; return; }
                pending = url;
                back.opacity = 0;
                back.scale = 1 + 0.15 * speed;
                back.blurAmt = 1;
                back.z = 2;
                front.z = 1;
                back.source = url;
                if (back.status === Image.Ready && back.source.toString() === url) reveal(back);
            }
            function reveal(img) {
                if (img !== back) return;
                revealAnim.img = img;
                revealAnim.restart();
            }

            Component.onCompleted: if (Wallpapers.shown) { imgA.source = "file://" + Wallpapers.shown; imgA.opacity = 1; }
            Connections {
                target: Wallpapers
                function onShownChanged() { stage.swapTo(Wallpapers.shown); }
            }

            ParallelAnimation {
                id: revealAnim
                property Image img: null
                Anim { target: revealAnim.img; property: "opacity"; to: 1; duration: Theme.calm ? 0 : 1300 * stage.speed; easing.type: Easing.OutCubic }
                Anim { target: revealAnim.img; property: "scale"; to: 1; duration: Theme.calm ? 0 : 1900 * stage.speed; easing.type: Easing.OutQuint }
                Anim { target: revealAnim.img; property: "blurAmt"; to: 0; duration: Theme.calm ? 0 : 1500 * stage.speed; easing.type: Easing.OutCubic }
                onFinished: stage.finishReveal(revealAnim.img)
            }

            component Wall: Image {
                id: self
                property real blurAmt: 0
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                opacity: 0
                sourceSize.width: win.width + win.parallaxMax
                layer.enabled: blurAmt > 0.01
                layer.effect: MultiEffect { blurEnabled: true; blurMax: 64; blur: self.blurAmt }
                onStatusChanged: if (status === Image.Ready && source.toString() === stage.pending) stage.reveal(self)
            }

            Wall { id: imgA; z: 1 }
            Wall { id: imgB; z: 0 }
        }

        // Scrim for legibility of the desktop clock
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.55; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.alpha(Theme.surface, 0.55) }
            }
        }

        // ── audio: aura behind the clock that blooms on beats ──
        Item {
            id: auraFade
            anchors.fill: parent
            opacity: Viz.active && win.live ? 1 : 0              // on/off fade only
            visible: opacity > 0.01
            Behavior on opacity { Anim { duration: Theme.slow } }
        }
        // drawn as a real circle (Shape) so nothing exists outside it — no faint box edges
        Shape {
            id: aura
            width: 900; height: 900
            // centred on the (morphing) clock
            x: dclock.x + dclock.focusX - width / 2
            y: dclock.y + dclock.focusY - height / 2
            visible: auraFade.visible
            opacity: auraFade.visible ? auraFade.opacity * (0.15 + Viz.level * 0.45 + Viz.pulse * 0.4) : 0   // live
            scale: auraFade.visible ? 0.85 + Viz.bass * 0.25 + Viz.pulse * 0.2 : 0.85
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: 450; centerY: 450; centerRadius: 450
                    focalX: 450; focalY: 450
                    GradientStop { position: 0.0; color: Qt.alpha(Theme.primary, 0.9) }
                    GradientStop { position: 0.4; color: Qt.alpha(Theme.magenta, 0.35) }
                    GradientStop { position: 1.0; color: Qt.alpha(Theme.magenta, 0.0) }
                }
                PathAngleArc { centerX: 450; centerY: 450; radiusX: 450; radiusY: 450; startAngle: 0; sweepAngle: 360 }
            }
        }

        // ── customizable desktop widgets (right-click the desktop to edit) ──
        DesktopWidgets { live: win.live }

        // ── desktop clock: digital <-> analog morph (click it / Super+F10 / >clock) ──
        DesktopClock {
            id: dclock
            live: win.live
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 30
            anchors.bottomMargin: 0
        }
    }
}
