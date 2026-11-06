import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// Every described keybind, grouped into cards, searchable. Generated live from `hyprctl binds`.
Overlay {
    id: root
    name: "cheatsheet"
    dim: 0.55

    property string filter: ""
    onOpened: { Binds.refresh(); search.text = ""; search.forceActiveFocus(); flick.contentY = 0; }

    readonly property var shown: {
        const q = filter.toLowerCase();
        const cats = Binds.categories.map(c => ({
            name: c.name,
            binds: q ? c.binds.filter(b => (c.name + " " + b.desc + " " + b.keys.join(" ")).toLowerCase().includes(q)) : c.binds
        })).filter(c => c.binds.length > 0);
        return cats;
    }
    readonly property int total: shown.reduce((a, c) => a + c.binds.length, 0)
    readonly property var catIcons: ({
        "Apps": "apps", "Shell": "dashboard", "Theme": "palette", "Notifications": "notifications", "Windows": "select_window",
        "Focus": "center_focus_strong", "Resize": "open_in_full", "Groups": "tab", "Workspaces": "grid_view",
        "Scratchpads": "layers", "Modes": "tune", "Zoom": "zoom_in", "Capture": "screenshot_monitor",
        "Clipboard": "content_paste", "Audio": "volume_up", "Media": "music_note", "Display": "brightness_6", "Session": "power_settings_new"
    })

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 60
        anchors.leftMargin: 60
        anchors.rightMargin: 60
        anchors.bottomMargin: 30
        spacing: 22
        opacity: root.progress
        transform: Translate { y: (1 - root.progress) * 50 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            GradientText { text: "keybinds"; font.pixelSize: 56; font.weight: Font.Black; font.letterSpacing: -2 }
            Txt { text: root.total + " shortcuts · " + root.shown.length + " groups"; color: Theme.subtext; font.pixelSize: 14; Layout.alignment: Qt.AlignBottom; bottomPadding: 12 }
            Item { Layout.fillWidth: true }
            Rectangle {
                Layout.preferredWidth: 420
                Layout.preferredHeight: 50
                radius: 25
                color: Theme.chip
                GlowBorder { radius: 25; thickness: search.activeFocus ? 2 : 1 }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    Icon { icon: "search"; size: 22; color: Theme.primary }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 16
                        onTextChanged: root.filter = text
                        Keys.onEscapePressed: Shell.close()
                        Txt { visible: !search.text; text: "filter…  (try “screenshot”, “alt”, “workspace”)"; color: Qt.alpha(Theme.subtext, 0.6); font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: flow.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Flow {
                id: flow
                width: parent.width
                spacing: 16

                Repeater {
                    model: root.shown
                    Glass {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property real p: Math.max(0, Math.min(1, (root.progress - Math.min(index, 12) * 0.035) / 0.5))
                        width: Math.floor((flow.width - 16 * 3) / 4)
                        height: col.implicitHeight + 30
                        radius: 22
                        opacity: p
                        scale: 0.9 + 0.1 * p
                        color: Qt.alpha(Theme.surface, 0.78)
                        MouseArea { anchors.fill: parent }

                        ColumnLayout {
                            id: col
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 8
                            RowLayout {
                                spacing: 8
                                Rectangle {
                                    width: 30; height: 30; radius: 10
                                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.tertiary } }
                                    Icon { anchors.centerIn: parent; icon: root.catIcons[card.modelData.name] ?? "keyboard"; size: 17; fill: 1; color: Theme.onPrimary }
                                }
                                Txt { text: card.modelData.name.toUpperCase(); font.pixelSize: 13; font.weight: Font.Black; font.letterSpacing: 2 }
                                Item { Layout.fillWidth: true }
                                Txt { text: card.modelData.binds.length; font.family: Theme.mono; font.pixelSize: 11; color: Theme.subtext }
                            }
                            Repeater {
                                model: card.modelData.binds
                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Txt { Layout.fillWidth: true; text: parent.modelData.desc; font.pixelSize: 12; color: Theme.subtext; elide: Text.ElideRight }
                                    Row {
                                        spacing: 3
                                        Repeater { model: parent.parent.modelData.keys; Keycap { required property string modelData; text: modelData } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
