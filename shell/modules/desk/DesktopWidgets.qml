import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// Desktop widget layer (lives in the wallpaper window, under every app window).
// Edit mode (right-click the empty desktop · Super+F12 · >widgets): drag to move (20 px grid),
// −/+ to resize, × to remove, "+ Add widget" opens the gallery. Layout persists (services/Widgets).
Item {
    id: root
    property bool live: true          // desktop visible (no windows) — gates idle animation
    anchors.fill: parent

    readonly property var files: ({
        sysmon: "WSysmon.qml", weather: "WWeather.qml", calendar: "WCalendar.qml",
        notes: "WNotes.qml", todo: "WTodo.qml", apps: "WApps.qml", timer: "WTimer.qml",
        nowplaying: "WNowPlaying.qml"
    })

    // right-click on empty desktop toggles edit mode (left clicks pass to wallpaper/clock as before)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: Widgets.editMode = !Widgets.editMode
    }

    // ── placed widgets ───────────────────────────────────
    Repeater {
        model: ScriptModel { values: Widgets.items; objectProp: "uid" }

        delegate: Item {
            id: frame
            required property var modelData
            readonly property int uid: modelData.uid
            x: modelData.x
            y: modelData.y
            width: content.item ? content.item.implicitWidth : 200
            height: content.item ? content.item.implicitHeight : 120
            transformOrigin: Item.TopLeft
            scale: modelData.scale * popScale
            property real popScale: 0.6
            opacity: 0
            Component.onCompleted: appear.start()
            ParallelAnimation {
                id: appear
                NumberAnimation { target: frame; property: "opacity"; to: 1; duration: Theme.normal }
                NumberAnimation { target: frame; property: "popScale"; to: 1; duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            }
            SequentialAnimation {
                id: vanish
                ParallelAnimation {
                    NumberAnimation { target: frame; property: "opacity"; to: 0; duration: Theme.normal }
                    NumberAnimation { target: frame; property: "popScale"; to: 0.5; duration: Theme.normal; easing.type: Easing.InBack }
                }
                ScriptAction { script: Widgets.remove(frame.uid) }
            }

            // edit-mode wiggle (iOS style), each widget slightly out of phase
            rotation: wiggleOn ? wig : 0
            readonly property bool wiggleOn: Widgets.editMode && !dragArea.drag.active && !Theme.calm
            property real wig: 0
            SequentialAnimation on wig {
                running: frame.wiggleOn
                loops: Animation.Infinite
                PauseAnimation { duration: (frame.uid * 73) % 160 }
                NumberAnimation { to: 0.7; duration: 140; easing.type: Easing.InOutSine }
                NumberAnimation { to: -0.7; duration: 280; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: 140; easing.type: Easing.InOutSine }
            }

            readonly property bool bare: content.item?.bare ?? false
            Glass {
                anchors.fill: parent
                radius: 24
                visible: !frame.bare || Widgets.editMode       // bare widgets draw their own look
                color: Qt.alpha(Theme.surface, frame.bare ? 0.35 : 0.62)
                fancy: Widgets.editMode
                glow: Widgets.editMode && dragArea.drag.active
            }
            Loader {
                id: content
                anchors.fill: parent
                Component.onCompleted: setSource(root.files[frame.modelData.type] ?? "", { uid: frame.uid })
                onLoaded: if ("live" in item) item.live = Qt.binding(() => root.live)
            }

            // drag surface (edit mode only, above the content so widgets don't react while editing)
            MouseArea {
                id: dragArea
                anchors.fill: parent
                enabled: Widgets.editMode
                visible: enabled
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: frame
                drag.minimumX: 0; drag.minimumY: 60
                drag.maximumX: root.width - frame.width * frame.scale
                drag.maximumY: root.height - frame.height * frame.scale
                onReleased: {
                    const sx = Math.round(frame.x / 20) * 20, sy = Math.round(frame.y / 20) * 20;
                    frame.x = sx; frame.y = sy;
                    Widgets.update(frame.uid, { x: sx, y: sy });
                }
            }

            // ── edit chrome: remove badge + size buttons ──
            Rectangle {   // ×
                visible: Widgets.editMode
                width: 28; height: 28; radius: 14
                x: -10; y: -10
                color: Theme.red
                scale: Widgets.editMode ? 1 : 0
                Behavior on scale { Anim { easing.type: Theme.springy } }
                Icon { anchors.centerIn: parent; icon: "close"; size: 16; weight: 800; color: "#1a0006" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: vanish.start() }
            }
            Row {
                visible: Widgets.editMode
                anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: -10
                spacing: 4
                Repeater {
                    model: [["remove", -0.1], ["add", 0.1]]
                    Rectangle {
                        required property var modelData
                        width: 26; height: 26; radius: 13
                        color: Theme.primary
                        Icon { anchors.centerIn: parent; icon: parent.modelData[0]; size: 16; weight: 800; color: Theme.onPrimary }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Widgets.update(frame.uid, { scale: Math.max(0.6, Math.min(1.6, Math.round((frame.modelData.scale + parent.modelData[1]) * 10) / 10)) })
                        }
                    }
                }
            }
        }
    }

    // ── edit bar (top centre) ────────────────────────────
    Glass {
        id: bar
        width: barRow.implicitWidth + 28
        height: 52
        radius: 26
        fancy: true
        glow: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: Widgets.editMode ? 70 : -80
        Behavior on y { Anim { duration: Theme.slow; easing.type: Theme.springy } }
        visible: y > -70
        RowLayout {
            id: barRow
            anchors.centerIn: parent
            spacing: 12
            Icon { icon: "edit"; size: 20; fill: 1; color: Theme.primary }
            Txt { text: "Editing widgets"; font.pixelSize: 14; font.weight: Font.Black }
            Txt { text: "drag to move · −/+ resize · × remove"; font.pixelSize: 12; color: Theme.subtext }
            Rectangle {
                width: addRow.implicitWidth + 24; height: 34; radius: 17
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.tertiary } }
                Row { id: addRow; anchors.centerIn: parent; spacing: 6
                    Icon { icon: "add"; size: 16; weight: 800; color: Theme.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                    Txt { text: "Add widget"; font.pixelSize: 12; font.weight: Font.Black; color: Theme.onPrimary }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Widgets.galleryOpen = !Widgets.galleryOpen }
            }
            Rectangle {
                width: doneTxt.implicitWidth + 24; height: 34; radius: 17
                color: Theme.chip
                Txt { id: doneTxt; anchors.centerIn: parent; text: "Done"; font.pixelSize: 12; font.weight: Font.Bold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Widgets.editMode = false }
            }
        }
    }

    // ── gallery ──────────────────────────────────────────
    Glass {
        id: gallery
        width: 640
        height: grid.implicitHeight + 70
        radius: 28
        fancy: true
        glow: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: 140
        opacity: Widgets.galleryOpen ? 1 : 0
        scale: Widgets.galleryOpen ? 1 : 0.9
        visible: opacity > 0.01
        Behavior on opacity { Anim {} }
        Behavior on scale { Anim { duration: Theme.slow; easing.type: Theme.springy } }
        MouseArea { anchors.fill: parent }

        Txt { x: 24; y: 18; text: "Add a widget"; font.pixelSize: 18; font.weight: Font.Black }
        GridLayout {
            id: grid
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.topMargin: 54; anchors.leftMargin: 18; anchors.rightMargin: 18
            columns: 2
            rowSpacing: 10; columnSpacing: 10
            Repeater {
                model: Widgets.galleryOpen ? Widgets.catalog : []
                Rectangle {
                    id: cat
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 18
                    color: gm.containsMouse ? Theme.glassHi : Theme.chip
                    Behavior on color { CAnim {} }
                    opacity: 0
                    Component.onCompleted: catIn.start()
                    SequentialAnimation { id: catIn; PauseAnimation { duration: cat.index * 40 } Anim { target: cat; property: "opacity"; to: 1 } }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12
                        spacing: 12
                        Rectangle {
                            Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 13
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primary } GradientStop { position: 1; color: Theme.tertiary } }
                            Icon { anchors.centerIn: parent; icon: cat.modelData.icon; size: 22; fill: 1; color: Theme.onPrimary; rotation: gm.containsMouse ? -10 : 0; Behavior on rotation { Anim { easing.type: Theme.springy } } }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Txt { text: cat.modelData.name; font.pixelSize: 13; font.weight: Font.Bold }
                            Txt { Layout.fillWidth: true; text: cat.modelData.desc; font.pixelSize: 11; color: Theme.subtext }
                        }
                        Icon { icon: "add_circle"; size: 22; fill: gm.containsMouse ? 1 : 0; color: Theme.primary }
                    }
                    MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Widgets.add(cat.modelData.type) }
                }
            }
        }
    }
}
