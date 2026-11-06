import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// CPU / RAM / temperature rings + CPU history graph
Item {
    property int uid: -1
    implicitWidth: 340
    implicitHeight: 216
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        RowLayout {
            Icon { icon: "monitoring"; size: 18; fill: 1; color: Theme.primary }
            Txt { text: "SYSTEM"; font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.primary }
            Item { Layout.fillWidth: true }
            Txt { text: "up " + Sys.uptime; font.family: Theme.mono; font.pixelSize: 10; color: Theme.subtext }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Repeater {
                model: [
                    { v: Sys.cpu, i: "memory", l: "CPU", t: Math.round(Sys.cpu * 100) + "%", c: Theme.primary },
                    { v: Sys.mem, i: "memory_alt", l: "RAM", t: Sys.memUsedGb.toFixed(1) + "G", c: Theme.tertiary },
                    { v: Sys.temp / 100, i: "device_thermostat", l: "TEMP", t: Math.round(Sys.temp) + "°", c: Theme.orange }
                ]
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    Ring { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 72; Layout.preferredHeight: 72; thickness: 7; value: parent.modelData.v; color: parent.modelData.c; icon: parent.modelData.i; label: parent.modelData.t; iconSize: 17 }
                    Txt { Layout.alignment: Qt.AlignHCenter; text: parent.modelData.l; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.subtext }
                }
            }
        }
        Graph { Layout.fillWidth: true; Layout.fillHeight: true; values: Sys.cpuHistory; color: Theme.primary }
    }
}
