import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.widgets

// Workspace pills with a stretchy gradient indicator and per-window dots.
Rectangle {
    id: root
    property HyprlandMonitor monitor
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property var wsList: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property int shown: Math.max(6, activeId, ...wsList.map(w => w.id))
    readonly property int pill: 30

    height: 36
    width: row.width + 8
    radius: height / 2
    color: Theme.chip
    Behavior on width { Anim { duration: Theme.slow; easing.type: Theme.springy } }

    function ws(id) { return wsList.find(w => w.id === id) ?? null; }

    // indicator: leading edge moves fast, trailing edge lags -> stretch
    Item {
        id: ind
        readonly property Item target: rep.itemAt(root.activeId - 1)
        property real l: target ? target.x + row.x : 4
        property real r: target ? target.x + row.x + target.width : 4 + root.pill
        property bool goingRight: true
        onTargetChanged: if (target) goingRight = target.x + row.x > lEdge
        property real lEdge: l
        property real rEdge: r
        Behavior on lEdge { Anim { duration: ind.goingRight ? Theme.slow : Theme.normal; easing.type: Easing.OutQuint } }
        Behavior on rEdge { Anim { duration: ind.goingRight ? Theme.normal : Theme.slow; easing.type: Easing.OutQuint } }
        x: lEdge
        width: rEdge - lEdge
        height: 28 + Viz.pulse * 6        // audio: the active pill bounces on beats
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.primary }
                GradientStop { position: 0.6; color: Theme.tertiary }
                GradientStop { position: 1; color: Theme.magenta }
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            id: rep
            model: root.shown

            Item {
                id: cell
                required property int index
                readonly property int wid: index + 1
                readonly property HyprlandWorkspace w: root.ws(wid)
                readonly property int windows: w?.toplevels?.values?.length ?? 0
                readonly property bool isActive: wid === root.activeId
                readonly property bool urgent: w?.urgent ?? false

                width: isActive ? root.pill + 18 : root.pill
                height: 28
                Behavior on width { Anim { duration: Theme.normal; easing.type: Theme.springy } }

                Txt {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: cell.windows > 0 && !cell.isActive ? -3 : 0
                    text: cell.wid
                    font.family: Theme.mono
                    font.pixelSize: cell.isActive ? 14 : 12
                    font.weight: cell.isActive ? Font.Black : Font.Bold
                    color: cell.isActive ? Theme.onPrimary : cell.urgent ? Theme.red : cell.windows > 0 ? Theme.text : Qt.alpha(Theme.subtext, 0.5)
                    Behavior on anchors.verticalCenterOffset { Anim {} }
                }

                // window dots
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    spacing: 2
                    opacity: cell.isActive ? 0 : 1
                    Behavior on opacity { Anim {} }
                    Repeater {
                        model: Math.min(4, cell.windows)
                        Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.primary }
                    }
                }

                // urgent pulse
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "transparent"
                    border.color: Theme.red
                    border.width: 2
                    visible: cell.urgent
                    SequentialAnimation on opacity {
                        running: cell.urgent; loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${cell.wid} })`)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: w => Hyprland.dispatch(`hl.dsp.focus({ workspace = "e${w.angleDelta.y > 0 ? "-" : "+"}1" })`)
    }
}
