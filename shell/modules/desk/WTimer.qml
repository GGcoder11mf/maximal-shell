import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// Pomodoro: big ring around the countdown + presets. Shares the bar timer (Timers service).
Item {
    property int uid: -1
    implicitWidth: 260
    implicitHeight: 300
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        RowLayout {
            Icon { icon: "timer"; size: 18; fill: 1; color: Theme.primary }
            Txt { text: Timers.active ? Timers.label.toUpperCase() : "POMODORO"; font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.primary }
        }
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 150; Layout.preferredHeight: 150
            Ring {
                anchors.fill: parent
                thickness: 10
                value: Timers.active ? Timers.progress : 0
                color: Timers.active && Timers.remaining < 60 ? Theme.red : Theme.primary
            }
            Column {
                anchors.centerIn: parent
                spacing: 0
                GradientText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Timers.active ? Timers.fmt(Timers.remaining) : "--:--"
                    font.pixelSize: 34; font.weight: Font.Black; glow: false
                }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Timers.paused ? "paused" : Timers.active ? "of " + Timers.fmt(Timers.total) : "pick a preset"; font.pixelSize: 10; color: Theme.subtext }
            }
            MouseArea { anchors.fill: parent; cursorShape: Timers.active ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: Timers.togglePause() }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Repeater {
                model: [[5, "Break"], [15, "Short"], [25, "Focus"], [50, "Deep"]]
                Rectangle {
                    id: pre
                    required property var modelData
                    width: 46; height: 30; radius: 15
                    color: pm.containsMouse ? Theme.primary : Theme.chip
                    Behavior on color { CAnim {} }
                    scale: pm.pressed ? 0.9 : 1
                    Behavior on scale { Anim { easing.type: Theme.springy } }
                    Txt { anchors.centerIn: parent; text: pre.modelData[0] + "m"; font.pixelSize: 12; font.weight: Font.Bold; color: pm.containsMouse ? Theme.onPrimary : Theme.text }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Timers.start(pre.modelData[0] * 60, pre.modelData[1]) }
                }
            }
        }
        IconBtn { Layout.alignment: Qt.AlignHCenter; visible: Timers.active; icon: "stop"; size: 30; onClicked: Timers.cancel() }
    }
}
