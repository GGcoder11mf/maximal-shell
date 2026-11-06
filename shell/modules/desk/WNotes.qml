import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// Sticky note — click and type; saved automatically.
Item {
    id: root
    required property int uid
    implicitWidth: 300
    implicitHeight: 240
    property var store: Widgets.dataOf(uid)

    Rectangle {   // paper tint
        anchors.fill: parent
        radius: 24
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.tertiaryContainer, 0.55) }
            GradientStop { position: 1; color: Qt.alpha(Theme.primaryContainer, 0.35) }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        RowLayout {
            Icon { icon: "sticky_note_2"; size: 18; fill: 1; color: Theme.tertiary }
            Txt { text: "NOTE"; font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 2; color: Theme.tertiary }
            Item { Layout.fillWidth: true }
            Txt { text: edit.length + " chars"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.subtext; visible: edit.activeFocus }
        }
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: edit.contentHeight
            clip: true
            TextEdit {
                id: edit
                width: flick.width
                wrapMode: TextEdit.Wrap
                text: root.store.text ?? ""
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 14
                selectionColor: Theme.primaryContainer
                selectedTextColor: Theme.onPrimaryContainer
                onTextChanged: if (text !== (root.store.text ?? "")) Widgets.setData(root.uid, Object.assign({}, root.store, { text }))
                Txt {
                    visible: !edit.text && !edit.activeFocus
                    text: "Click to write…"
                    color: Qt.alpha(Theme.subtext, 0.6)
                    font.pixelSize: 14
                }
            }
        }
    }
}
