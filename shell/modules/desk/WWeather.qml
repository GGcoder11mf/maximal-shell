import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// Current weather + next hours
Item {
    property int uid: -1
    implicitWidth: 340
    implicitHeight: 196
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6
        RowLayout {
            spacing: 12
            Icon { icon: Weather.currentIcon; size: 58; fill: 1; color: Weather.night ? Theme.secondary : Theme.yellow }
            ColumnLayout {
                spacing: -4
                GradientText { text: Weather.temp + "°"; font.pixelSize: 44; font.weight: Font.Black; glow: false }
                Txt { text: "feels " + Weather.feels + "°"; font.pixelSize: 11; color: Theme.subtext }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 2
                Txt { Layout.alignment: Qt.AlignRight; text: "↑ " + Weather.high + "°"; font.family: Theme.mono; font.pixelSize: 12; color: Theme.orange }
                Txt { Layout.alignment: Qt.AlignRight; text: "↓ " + Weather.low + "°"; font.family: Theme.mono; font.pixelSize: 12; color: Theme.cyan }
            }
        }
        Txt { Layout.fillWidth: true; text: Weather.desc + "   ·   💧 " + Weather.humidity + "%   ·   " + Weather.wind + " km/h"; font.pixelSize: 12; color: Theme.subtext }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: Weather.hourly.slice(0, 8)
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 1
                    Txt { Layout.alignment: Qt.AlignHCenter; text: parent.modelData.time.slice(0, 2); font.family: Theme.mono; font.pixelSize: 9; color: Theme.subtext }
                    Icon { Layout.alignment: Qt.AlignHCenter; icon: Weather.icon(parent.modelData.code, false); size: 16; fill: 1; color: Theme.primary }
                    Txt { Layout.alignment: Qt.AlignHCenter; text: parent.modelData.temp + "°"; font.pixelSize: 10; font.weight: Font.Bold }
                }
            }
        }
    }
}
