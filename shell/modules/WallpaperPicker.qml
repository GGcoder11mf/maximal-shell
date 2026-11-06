import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.widgets

// 3D cover-flow wallpaper picker + palette style chips. ←/→ browse, Enter apply, R random, S style.
Overlay {
    id: root
    name: "wallpapers"
    dim: 0.4

    readonly property var schemes: [
        ["scheme-vibrant", "Vibrant"], ["scheme-expressive", "Expressive"], ["scheme-fruit-salad", "Fruit salad"],
        ["scheme-rainbow", "Rainbow"], ["scheme-tonal-spot", "Tonal"], ["scheme-content", "Content"],
        ["scheme-fidelity", "Fidelity"], ["scheme-monochrome", "Mono"]
    ]

    onOpened: {
        Wallpapers.refresh();
        const i = Wallpapers.list.indexOf(Wallpapers.current);
        view.currentIndex = Math.max(0, i);
        view.forceActiveFocus();
    }

    function apply() { Wallpapers.set(Wallpapers.list[view.currentIndex]); }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 90
        anchors.bottomMargin: 60
        spacing: 26
        opacity: root.progress

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            GradientText { Layout.alignment: Qt.AlignHCenter; text: "wallpapers"; font.pixelSize: 56; font.weight: Font.Black; font.letterSpacing: -2 }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                text: (view.currentIndex + 1) + " / " + Wallpapers.list.length + "   ·   " + (Wallpapers.list[view.currentIndex] ?? "").split("/").pop()
                font.family: Theme.mono; font.pixelSize: 12; color: Theme.subtext
            }
        }

        PathView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: Wallpapers.list
            pathItemCount: Math.min(7, Wallpapers.list.length)
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: Theme.slow
            snapMode: PathView.SnapToItem
            transform: Translate { y: (1 - root.progress) * 80 }

            path: Path {
                startX: -view.width * 0.1; startY: view.height * 0.5
                PathAttribute { name: "itemScale"; value: 0.45 }
                PathAttribute { name: "itemZ"; value: 0 }
                PathAttribute { name: "itemAngle"; value: 55 }
                PathAttribute { name: "itemOpacity"; value: 0.25 }
                PathLine { x: view.width * 0.5; y: view.height * 0.5 }
                PathAttribute { name: "itemScale"; value: 1.0 }
                PathAttribute { name: "itemZ"; value: 100 }
                PathAttribute { name: "itemAngle"; value: 0 }
                PathAttribute { name: "itemOpacity"; value: 1 }
                PathLine { x: view.width * 1.1; y: view.height * 0.5 }
                PathAttribute { name: "itemScale"; value: 0.45 }
                PathAttribute { name: "itemZ"; value: 0 }
                PathAttribute { name: "itemAngle"; value: -55 }
                PathAttribute { name: "itemOpacity"; value: 0.25 }
            }

            delegate: Item {
                id: d
                required property string modelData
                required property int index
                readonly property bool cur: PathView.isCurrentItem
                readonly property bool applied: modelData === Wallpapers.current
                width: 560; height: 340
                scale: PathView.itemScale ?? 1
                z: PathView.itemZ ?? 0
                opacity: PathView.itemOpacity ?? 1
                transform: Rotation { origin.x: d.width / 2; origin.y: d.height / 2; axis { x: 0; y: 1; z: 0 } angle: d.PathView.itemAngle ?? 0 }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 28
                    color: Theme.chip
                    Image {
                        anchors.fill: parent
                        source: Wallpapers.thumb(d.modelData)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        onStatusChanged: if (status === Image.Error) source = "file://" + d.modelData
                        sourceSize.width: 560
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 70
                        gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha("black", 0.6) } }
                        visible: d.applied
                        Row {
                            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 16
                            spacing: 6
                            Icon { icon: "check_circle"; size: 18; fill: 1; color: Theme.primary }
                            Txt { text: "current"; font.pixelSize: 12; font.weight: Font.Bold }
                        }
                    }
                }
                GlowBorder { visible: d.cur; radius: 28; thickness: 4; glow: true; period: 2500 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: d.cur ? root.apply() : view.currentIndex = d.index
                }
            }

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Left || e.key === Qt.Key_H) view.decrementCurrentIndex();
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_L) view.incrementCurrentIndex();
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.apply();
                else if (e.key === Qt.Key_R) { view.currentIndex = Math.floor(Math.random() * Wallpapers.list.length); root.apply(); }
                else if (e.key === Qt.Key_S) {
                    const i = root.schemes.findIndex(s => s[0] === Wallpapers.scheme);
                    Wallpapers.setScheme(root.schemes[(i + 1) % root.schemes.length][0]);
                }
                else if (e.key === Qt.Key_Escape) Shell.close();
                else return;
                e.accepted = true;
            }
            WheelHandler { onWheel: e => e.angleDelta.y > 0 ? view.decrementCurrentIndex() : view.incrementCurrentIndex() }
        }

        // palette style chips
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Txt { text: "PALETTE STYLE"; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter; rightPadding: 6 }
            Repeater {
                model: root.schemes
                Rectangle {
                    required property var modelData
                    readonly property bool on: Wallpapers.scheme === modelData[0]
                    width: sl.implicitWidth + 26; height: 34; radius: 17
                    color: on ? "transparent" : sm.containsMouse ? Theme.glassHi : Theme.chip
                    gradient: on ? g : null
                    Gradient { id: g; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.tertiary } }
                    scale: sm.pressed ? 0.92 : 1
                    Behavior on scale { Anim { easing.type: Theme.springy } }
                    Txt { id: sl; anchors.centerIn: parent; text: parent.modelData[1]; font.pixelSize: 12; font.weight: Font.Bold; color: parent.on ? Theme.onPrimary : Theme.text }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Wallpapers.setScheme(parent.modelData[0]) }
                }
            }
        }

        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: "←  →  browse     ↵  apply     R  random     S  next palette style     esc  close"
            font.family: Theme.mono; font.pixelSize: 12; color: Qt.alpha(Theme.subtext, 0.7)
        }
    }
}
