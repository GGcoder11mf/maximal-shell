import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// Month grid; scroll or arrows to change month, click title to jump back to today.
ColumnLayout {
    id: root
    property date today: new Date()
    property int offset: 0
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int firstDow: (month.getDay() + 6) % 7          // Monday-first
    readonly property int days: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        IconBtn { icon: "chevron_left"; size: 30; onClicked: root.offset-- }
        Item { Layout.fillWidth: true }
        GradientText {
            text: Qt.formatDate(root.month, "MMMM yyyy")
            font.pixelSize: 18; font.weight: Font.Black
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.offset = 0 }
        }
        Item { Layout.fillWidth: true }
        IconBtn { icon: "chevron_right"; size: 30; onClicked: root.offset++ }
    }

    GridLayout {
        id: grid
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Txt {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: 11; font.weight: Font.Black
                color: index >= 5 ? Theme.tertiary : Theme.subtext
            }
        }

        Repeater {
            model: 42
            Item {
                id: cell
                required property int index
                readonly property int day: index - root.firstDow + 1
                readonly property bool inMonth: day >= 1 && day <= root.days
                readonly property bool isToday: inMonth && root.offset === 0 && day === root.today.getDate()
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                visible: index < 35 || root.firstDow + root.days > 35

                Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 32; radius: 16
                    visible: cell.isToday || hov.hovered
                    color: cell.isToday ? "transparent" : Theme.chip
                    gradient: cell.isToday ? todayGrad : null
                    Gradient { id: todayGrad; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.magenta } }
                    SequentialAnimation on scale {
                        running: cell.isToday && !Theme.calm; loops: Animation.Infinite
                        NumberAnimation { to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                    }
                }
                Txt {
                    anchors.centerIn: parent
                    text: cell.inMonth ? cell.day : ""
                    font.family: Theme.mono
                    font.pixelSize: 12
                    font.weight: cell.isToday ? Font.Black : Font.Medium
                    color: cell.isToday ? Theme.onPrimary : (cell.index % 7 >= 5 ? Theme.tertiary : Theme.text)
                }
                HoverHandler { id: hov; enabled: cell.inMonth }
            }
        }
    }

    Item { Layout.fillHeight: true }

    WheelHandler { onWheel: e => root.offset += e.angleDelta.y > 0 ? -1 : 1 }
}
