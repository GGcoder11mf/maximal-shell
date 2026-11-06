import QtQuick
import qs.services
import qs.widgets

// CPU / RAM rings + temperature + network throughput. Click: dashboard.
Rectangle {
    id: root
    height: 36
    width: row.implicitWidth + 18
    radius: height / 2
    color: ma.containsMouse ? Theme.glassHi : Theme.chip
    Behavior on color { CAnim {} }

    component Stat: Row {
        property real value
        property string icon
        property string text
        property color tint
        spacing: 5
        Ring { width: 24; height: 24; thickness: 3; value: parent.value; color: parent.tint; icon: parent.icon; iconSize: 11; anchors.verticalCenter: parent.verticalCenter }
        Txt { text: parent.text; font.family: Theme.mono; font.pixelSize: 11; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter; width: 30 }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Stat { value: Sys.cpu; icon: "memory"; text: Math.round(Sys.cpu * 100) + "%"; tint: Sys.cpu > 0.85 ? Theme.red : Theme.primary }
        Stat { value: Sys.mem; icon: "memory_alt"; text: Math.round(Sys.mem * 100) + "%"; tint: Sys.mem > 0.85 ? Theme.red : Theme.tertiary }
        Stat { value: Sys.temp / 100; icon: "thermostat"; text: Math.round(Sys.temp) + "°"; tint: Sys.temp > 80 ? Theme.red : Theme.orange; visible: Sys.temp > 0 }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt { text: "↓ " + Sys.bytes(Sys.rx) + "/s"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.cyan; width: 62 }
            Txt { text: "↑ " + Sys.bytes(Sys.tx) + "/s"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.magenta; width: 62 }
        }
    }

    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Shell.toggle("dashboard") }
}
