import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services

// One notification. `popup` mode shows a timeout bar and auto-hides.
Glass {
    id: root
    required property QtObject entry
    property bool popup: true
    readonly property bool critical: entry?.urgency === NotificationUrgency.Critical
    readonly property var defaultAction: (entry?.actions ?? []).find(a => a.identifier === "default")
    readonly property var buttons: (entry?.actions ?? []).filter(a => a.identifier !== "default")

    fancy: critical
    glow: critical
    color: hov.hovered ? Theme.glassHi : Theme.glass
    implicitHeight: col.implicitHeight + 26
    radius: 22

    // accent stripe
    Rectangle {
        width: 4
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 14
        radius: 2
        gradient: Gradient {
            GradientStop { position: 0; color: root.critical ? Theme.red : Theme.primary }
            GradientStop { position: 1; color: root.critical ? Theme.orange : Theme.magenta }
        }
    }

    HoverHandler { id: hov }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: { if (root.defaultAction) root.defaultAction.invoke(); root.entry.popup = false; }
    }
    TapHandler {
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        onTapped: root.entry.notification?.dismiss()
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.rightMargin: 14
        anchors.topMargin: 13
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconImage {
                implicitSize: 16
                source: {
                    const e = root.entry;
                    if (!e) return "";
                    if (e.appIcon) return e.appIcon.startsWith("/") || e.appIcon.includes("://") ? e.appIcon : Quickshell.iconPath(e.appIcon, "dialog-information");
                    return Apps.icon(e.desktopEntry || e.appName, "dialog-information");
                }
            }
            Txt {
                Layout.fillWidth: true
                text: (root.entry?.appName || "Notification").toUpperCase()
                font.pixelSize: 10
                font.weight: Font.Black
                font.letterSpacing: 1.5
                color: root.critical ? Theme.red : Theme.primary
            }
            Txt {
                text: Qt.formatDateTime(root.entry?.time ?? new Date(), "HH:mm")
                font.family: Theme.mono
                font.pixelSize: 10
                color: Theme.subtext
            }
            IconBtn { size: 22; icon: "close"; onClicked: root.entry.notification?.dismiss() }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ClippingRectangle {
                visible: (root.entry?.image ?? "") !== ""
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                Layout.alignment: Qt.AlignTop
                radius: 14
                color: Theme.chip
                Image { anchors.fill: parent; source: root.entry?.image ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(104, 104) }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Txt {
                    Layout.fillWidth: true
                    text: root.entry?.summary ?? ""
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
                Txt {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.entry?.body ?? ""
                    textFormat: Text.StyledText
                    font.pixelSize: 12
                    color: Theme.subtext
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? 4 : 6
                    onLinkActivated: l => Qt.openUrlExternally(l)
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: root.buttons.length > 0
            spacing: 6
            Repeater {
                model: root.buttons
                Rectangle {
                    required property var modelData
                    width: at.implicitWidth + 22
                    height: 28
                    radius: 14
                    color: am.containsMouse ? Theme.primary : Theme.chip
                    Behavior on color { CAnim {} }
                    Txt { id: at; anchors.centerIn: parent; text: parent.modelData.text; font.pixelSize: 12; font.weight: Font.DemiBold; color: am.containsMouse ? Theme.onPrimary : Theme.text }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { parent.modelData.invoke(); root.entry.popup = false; } }
                }
            }
        }

        // timeout bar
        Rectangle {
            id: bar
            visible: root.popup && (root.entry?.timeout ?? 0) > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            radius: 2
            color: Theme.chip
            Rectangle {
                id: fill
                height: parent.height
                radius: 2
                width: parent.width
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.primary }
                    GradientStop { position: 1; color: Theme.tertiary }
                }
                NumberAnimation on width {
                    id: countdown
                    running: bar.visible
                    paused: hov.hovered
                    from: bar.width; to: 0
                    duration: root.entry?.timeout ?? 6000
                    onFinished: if (root.entry) root.entry.popup = false
                }
            }
        }
    }
}
