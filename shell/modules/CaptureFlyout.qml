import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Bottom-right flyout after a capture:
//   screenshot -> thumbnail + Copy / Edit / Open / Folder / Delete
//   recording  -> poster frame + Play / Folder / Copy path / Delete
//   colour     -> big swatch + HEX / RGB / HSL (click to copy)
// IPC (from the scripts):  qs -p <shell> ipc call capture shot <file>
//                          qs -p <shell> ipc call capture video <file> <poster.png>
//                          qs -p <shell> ipc call capture color <#rrggbb>
PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "maxi-notifs"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { right: true; bottom: true }
    implicitWidth: 440
    implicitHeight: 420
    color: "transparent"
    mask: Region { item: card.shown ? card : null }
    visible: card.shown || slide.running

    property string kind: "shot"        // shot | video | color
    property string file: ""
    property string poster: ""
    property color picked: "black"
    property string flash: ""           // "copied" feedback

    function show(k) {
        kind = k;
        flash = "";
        card.shown = true;
        hide.restart();
        pop.restart();
    }
    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }
    function copied(what) { flash = what; hide.restart(); }
    function act(id) {
        const f = q(file), dir = q(file.replace(/\/[^/]*$/, ""));
        if (id === "copy") { sh("wl-copy < " + f); copied("copied"); }
        else if (id === "edit") { card.shown = false; sh("satty --filename " + f + " --output-filename " + f + " --copy-command wl-copy"); }
        else if (id === "open") sh("xdg-open " + f);
        else if (id === "folder") sh("thunar " + dir);
        else if (id === "path") { sh("printf %s " + f + " | wl-copy"); copied("path copied"); }
        else if (id === "delete") { sh("gio trash " + f + " || rm -f " + f); card.shown = false; }
        else if (id === "pick") { card.shown = false; sh("sleep 0.3; " + Theme.scripts + "colorpick.sh"); }
    }

    Timer { id: hide; interval: 7000; onTriggered: if (!hov.hovered) card.shown = false; else restart() }

    IpcHandler {
        target: "capture"
        function shot(path: string): void { win.file = path; win.show("shot"); }
        function video(path: string, poster: string): void { win.file = path; win.poster = poster; win.show("video"); }
        function color(hex: string): void { win.picked = hex; win.show("color"); win.sh("printf %s " + win.q(hex) + " | wl-copy"); win.flash = "HEX copied"; }
    }

    Glass {
        id: card
        property bool shown: false
        width: 400
        height: col.implicitHeight + 28
        radius: 24
        fancy: true
        glow: true
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: shown ? parent.height - height - 18 : parent.height + 20
        Behavior on y { NumberAnimation { id: slide; duration: Theme.slow; easing.type: card.shown ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.3 } }
        HoverHandler { id: hov }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            // header
            RowLayout {
                Layout.fillWidth: true
                Icon {
                    icon: win.kind === "shot" ? "screenshot_monitor" : win.kind === "video" ? "videocam" : "colorize"
                    size: 18; fill: 1; color: Theme.primary
                }
                Txt {
                    text: win.kind === "shot" ? "SCREENSHOT" : win.kind === "video" ? "RECORDING SAVED" : "COLOUR PICKED"
                    font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.primary
                }
                Item { Layout.fillWidth: true }
                Txt {
                    text: win.flash
                    visible: text !== ""
                    font.pixelSize: 11; font.weight: Font.Bold; color: Theme.green
                    onTextChanged: if (text) flashAnim.restart()
                    SequentialAnimation on scale { id: flashAnim; running: false
                        NumberAnimation { from: 0.6; to: 1.15; duration: 140; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 1; duration: 220; easing.type: Easing.OutBack }
                    }
                }
                IconBtn { icon: "close"; size: 24; onClicked: card.shown = false }
            }

            // preview (shot / video)
            ClippingRectangle {
                visible: win.kind !== "color"
                Layout.fillWidth: true
                Layout.preferredHeight: 210
                radius: 16
                color: Theme.surfaceLow
                Image {
                    id: thumb
                    anchors.fill: parent
                    source: win.kind === "color" ? "" : (win.kind === "video" ? (win.poster ? "file://" + win.poster : "") : (win.file ? "file://" + win.file : ""))
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 760
                    asynchronous: true
                    cache: false
                    scale: 1.15
                }
                // recordings: a real inline preview — muted, looping (the poster shows until it starts)
                Video {
                    id: vid
                    anchors.fill: parent
                    visible: win.kind === "video" && playbackState === MediaPlayer.PlayingState
                    source: win.kind === "video" && card.shown ? "file://" + win.file : ""
                    fillMode: VideoOutput.PreserveAspectCrop
                    muted: true
                    loops: MediaPlayer.Infinite
                    autoPlay: true
                }
                Rectangle {   // tiny "playing" badge
                    visible: vid.visible
                    anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 10
                    width: pr.implicitWidth + 16; height: 22; radius: 11
                    color: Qt.alpha("black", 0.55)
                    Row {
                        id: pr
                        anchors.centerIn: parent
                        spacing: 4
                        Icon { icon: "volume_off"; size: 12; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                        Txt { text: "preview · click for sound"; font.pixelSize: 10; color: "white" }
                    }
                }
                Icon {
                    visible: win.kind === "video" && !vid.visible
                    anchors.centerIn: parent
                    icon: "play_circle"; size: 64; fill: 1; color: Qt.alpha("white", 0.9)
                }
                Rectangle {   // camera-flash sweep on arrival
                    id: flashFx
                    anchors.fill: parent
                    color: "white"
                    opacity: 0
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.sh("xdg-open " + win.q(win.file)) }
            }
            Txt {
                visible: win.kind !== "color"
                Layout.fillWidth: true
                text: win.file.split("/").pop()
                font.family: Theme.mono; font.pixelSize: 10; color: Theme.subtext
            }

            // colour swatch
            RowLayout {
                visible: win.kind === "color"
                Layout.fillWidth: true
                spacing: 14
                Rectangle {
                    id: swatch
                    Layout.preferredWidth: 110; Layout.preferredHeight: 110
                    radius: 55
                    color: win.picked
                    border.width: 3
                    border.color: Qt.alpha(Theme.text, 0.25)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: {
                            const c = win.picked;
                            const r = Math.round(c.r * 255), g = Math.round(c.g * 255), b = Math.round(c.b * 255);
                            const h = Math.round(Math.max(0, c.hslHue) * 360), s = Math.round(c.hslSaturation * 100), l = Math.round(c.hslLightness * 100);
                            return [["HEX", c.toString().toUpperCase()], ["RGB", `rgb(${r}, ${g}, ${b})`], ["HSL", `hsl(${h}, ${s}%, ${l}%)`]];
                        }
                        Rectangle {
                            id: fmtRow
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            radius: 10
                            color: fm.containsMouse ? Theme.glassHi : Theme.chip
                            Behavior on color { CAnim {} }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                Txt { text: fmtRow.modelData[0]; font.pixelSize: 10; font.weight: Font.Black; color: Theme.subtext; Layout.preferredWidth: 32 }
                                Txt { Layout.fillWidth: true; text: fmtRow.modelData[1]; font.family: Theme.mono; font.pixelSize: 12; font.weight: Font.Bold }
                                Icon { icon: "content_copy"; size: 14; color: Theme.subtext }
                            }
                            MouseArea {
                                id: fm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { win.sh("printf %s " + win.q(fmtRow.modelData[1]) + " | wl-copy"); win.copied(fmtRow.modelData[0] + " copied"); }
                            }
                        }
                    }
                }
            }

            // actions
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    // [icon, label, action id] — ids are handled by win.act() (models can't carry functions)
                    model: win.kind === "shot" ? [["content_copy", "Copy", "copy"], ["draw", "Edit", "edit"], ["open_in_new", "Open", "open"], ["folder_open", "Folder", "folder"], ["delete", "Delete", "delete"]]
                         : win.kind === "video" ? [["play_arrow", "Play", "open"], ["folder_open", "Folder", "folder"], ["link", "Copy path", "path"], ["delete", "Delete", "delete"]]
                         : [["colorize", "Pick again", "pick"]]
                    Rectangle {
                        id: act
                        required property var modelData
                        required property int index
                        width: al.implicitWidth + 40; height: 32; radius: 16
                        color: am.containsMouse ? (act.modelData[1] === "Delete" ? Qt.alpha(Theme.red, 0.3) : Theme.primary) : Theme.chip
                        Behavior on color { CAnim {} }
                        scale: am.pressed ? 0.92 : 1
                        Behavior on scale { Anim { easing.type: Theme.springy } }
                        opacity: 0
                        Component.onCompleted: appear.start()
                        SequentialAnimation {
                            id: appear
                            PauseAnimation { duration: act.index * 45 }
                            Anim { target: act; property: "opacity"; to: 1; duration: Theme.normal }
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Icon { icon: act.modelData[0]; size: 15; fill: am.containsMouse ? 1 : 0; color: am.containsMouse && act.modelData[1] !== "Delete" ? Theme.onPrimary : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                            Txt { id: al; text: act.modelData[1]; font.pixelSize: 12; font.weight: Font.Bold; color: am.containsMouse && act.modelData[1] !== "Delete" ? Theme.onPrimary : Theme.text }
                        }
                        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.act(act.modelData[2]) }
                    }
                }
            }
        }
    }

    // arrival animation: camera flash + thumbnail settle, or swatch pop
    ParallelAnimation {
        id: pop
        SequentialAnimation {
            NumberAnimation { target: flashFx; property: "opacity"; from: win.kind === "color" ? 0 : 0.85; to: 0; duration: 450; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: thumb; property: "scale"; from: 1.15; to: 1; duration: 700; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: swatch; property: "scale"; from: 0.2; to: 1.12; duration: 260; easing.type: Easing.OutQuad }
            NumberAnimation { target: swatch; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
        }
    }
}
