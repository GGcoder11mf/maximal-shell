import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.widgets

// System tray; collapses into a chevron, expands on click.
Rectangle {
    id: root
    required property var win
    property bool expanded: false
    readonly property var items: SystemTray.items.values
    visible: items.length > 0
    height: 36
    width: row.implicitWidth + 12
    radius: height / 2
    color: Theme.chip
    clip: true
    Behavior on width { Anim { duration: Theme.normal; easing.type: Theme.springy } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.expanded ? root.items : []
            delegate: Item {
                id: it
                required property SystemTrayItem modelData
                required property int index
                width: 28; height: 28
                opacity: 0; scale: 0.4
                Component.onCompleted: appear.start()
                ParallelAnimation {
                    id: appear
                    SequentialAnimation { PauseAnimation { duration: it.index * 40 } Anim { target: it; property: "opacity"; to: 1 } }
                    SequentialAnimation { PauseAnimation { duration: it.index * 40 } Anim { target: it; property: "scale"; to: 1; easing.type: Theme.springy } }
                }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: tma.containsMouse ? 20 : 17
                    Behavior on implicitSize { Anim { easing.type: Theme.springy } }
                    source: it.modelData.icon
                }
                QsMenuAnchor {
                    id: menu
                    menu: it.modelData.menu
                    anchor.window: root.win
                    anchor.rect.x: it.mapToItem(null, 0, 0).x
                    anchor.rect.y: 54
                    anchor.rect.width: it.width
                }
                MouseArea {
                    id: tma
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => {
                        if (m.button === Qt.LeftButton && !it.modelData.onlyMenu) it.modelData.activate();
                        else if (m.button === Qt.MiddleButton) it.modelData.secondaryActivate();
                        else if (it.modelData.hasMenu) menu.open();
                    }
                }
            }
        }

        IconBtn {
            size: 28
            icon: "chevron_left"
            rotation: root.expanded ? 180 : 0
            Behavior on rotation { Anim { easing.type: Theme.springy } }
            onClicked: root.expanded = !root.expanded
        }
    }
}
