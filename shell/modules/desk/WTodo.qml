import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// To-do list: type + Enter to add · click a task to tick it · × to delete · "clear done"
Item {
    id: root
    required property int uid
    implicitWidth: 320
    implicitHeight: Math.min(420, 110 + Math.max(1, tasks.length) * 36)
    property var tasks: Widgets.dataOf(uid).tasks ?? []
    function commit(t) { tasks = t; Widgets.setData(uid, { tasks: t }); }
    readonly property int done: tasks.filter(t => t.d).length

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        RowLayout {
            Icon { icon: "checklist"; size: 18; fill: 1; color: Theme.primary }
            Txt { text: "TO-DO"; font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.primary }
            Item { Layout.fillWidth: true }
            Txt { text: root.done + " / " + root.tasks.length; font.family: Theme.mono; font.pixelSize: 10; color: Theme.subtext }
            Txt {
                visible: root.done > 0
                text: "clear done"
                font.pixelSize: 10; font.weight: Font.Bold; color: Theme.tertiary
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.commit(root.tasks.filter(t => !t.d)) }
            }
        }
        // progress
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 4; radius: 2; color: Theme.chip
            Rectangle {
                height: parent.height; radius: 2
                width: parent.width * (root.tasks.length ? root.done / root.tasks.length : 0)
                Behavior on width { Anim { duration: Theme.slow; easing.type: Theme.springy } }
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.green } }
            }
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: ScriptModel { values: root.tasks.map((t, i) => ({ t: t.t, d: t.d, i })) }
            add: Transition { NumberAnimation { property: "x"; from: -40; duration: Theme.normal; easing.type: Easing.OutBack } NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal } }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast } }
            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Easing.OutCubic } }
            delegate: Item {
                id: task
                required property var modelData
                width: list.width
                height: 32
                Rectangle { anchors.fill: parent; radius: 10; color: tm.containsMouse ? Theme.chip : "transparent" }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6; anchors.rightMargin: 4
                    spacing: 8
                    Rectangle {
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18; radius: 6
                        color: task.modelData.d ? Theme.green : "transparent"
                        border.width: 2; border.color: task.modelData.d ? Theme.green : Theme.outline
                        Behavior on color { CAnim {} }
                        Icon { anchors.centerIn: parent; icon: "check"; size: 14; weight: 800; color: Theme.surface; scale: task.modelData.d ? 1 : 0; Behavior on scale { Anim { easing.type: Theme.springy } } }
                    }
                    Txt {
                        Layout.fillWidth: true
                        text: task.modelData.t
                        font.pixelSize: 13
                        font.strikeout: task.modelData.d
                        color: task.modelData.d ? Theme.subtext : Theme.text
                        opacity: task.modelData.d ? 0.6 : 1
                        Behavior on opacity { Anim {} }
                    }
                    IconBtn { visible: tm.containsMouse; size: 22; icon: "close"; onClicked: root.commit(root.tasks.filter((_, i) => i !== task.modelData.i)) }
                }
                MouseArea {
                    id: tm
                    anchors.fill: parent
                    anchors.rightMargin: 28
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.commit(root.tasks.map((t, i) => i === task.modelData.i ? { t: t.t, d: !t.d } : t))
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 12
            color: Theme.chip
            border.width: input.activeFocus ? 1 : 0
            border.color: Theme.primary
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                Icon { icon: "add"; size: 16; color: Theme.primary }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    clip: true
                    onAccepted: { const t = text.trim(); if (t) { root.commit([...root.tasks, { t, d: false }]); text = ""; } }
                    Txt { visible: !input.text; text: "Add a task…  (Enter)"; color: Qt.alpha(Theme.subtext, 0.6); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
