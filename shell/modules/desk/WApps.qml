import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.widgets

// Your most-launched apps (from the launcher's frecency store). Click to launch.
Item {
    id: root
    property int uid: -1
    implicitWidth: 340
    implicitHeight: 196
    property var counts: ({})
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/maximal/launches.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.counts = JSON.parse(text()); } catch (e) {} }
    }
    readonly property var apps: {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const used = all.filter(e => (counts[e.id] ?? 0) > 0).sort((a, b) => (counts[b.id] ?? 0) - (counts[a.id] ?? 0));
        const fill = ["firefox", "zen", "org.kde.dolphin", "thunar", "code", "spotify", "discord", "foot"]
            .map(id => all.find(e => e.id === id || e.id.startsWith(id))).filter(e => e && !used.includes(e));
        return [...used, ...fill].slice(0, 8);
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        RowLayout {
            Icon { icon: "apps"; size: 18; fill: 1; color: Theme.primary }
            Txt { text: "QUICK APPS"; font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.primary }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: root.apps
                Item {
                    id: app
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: am.containsMouse ? Theme.glassHi : Theme.chip
                        Behavior on color { CAnim {} }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitSize: am.containsMouse ? 32 : 28
                            Behavior on implicitSize { Anim { easing.type: Theme.springy } }
                            source: Quickshell.iconPath(app.modelData.icon ?? "", "application-x-executable")
                        }
                        Txt { anchors.horizontalCenter: parent.horizontalCenter; width: 64; horizontalAlignment: Text.AlignHCenter; text: app.modelData.name; font.pixelSize: 9; color: Theme.subtext }
                    }
                    scale: am.pressed ? 0.88 : 1
                    Behavior on scale { Anim { easing.type: Theme.springy } }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.modelData.execute() }
                }
            }
        }
    }
}
