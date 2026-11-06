import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.services
import qs.widgets

// Network, bluetooth, volume, notification bell → control center.
Rectangle {
    id: root
    height: 36
    width: row.implicitWidth + 12
    radius: height / 2
    color: ma.containsMouse ? Theme.glassHi : Theme.chip
    Behavior on color { CAnim {} }

    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi && d.connected)
    readonly property var wifiNet: wifi?.networks?.values?.find(n => n.connected) ?? null
    readonly property string netIcon: wired ? "lan" : wifiNet ? (wifiNet.signalStrength > 0.66 ? "signal_wifi_4_bar" : wifiNet.signalStrength > 0.33 ? "network_wifi_2_bar" : "network_wifi_1_bar") : "signal_wifi_off"
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool btOn: bt?.enabled ?? false
    readonly property int btConnected: (bt?.devices?.values ?? []).filter(d => d.connected).length

    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Shell.toggle("control") }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        IconBtn { size: 30; icon: root.netIcon; onClicked: Shell.toggle("control") }
        IconBtn {
            size: 30
            icon: !root.btOn ? "bluetooth_disabled" : root.btConnected > 0 ? "bluetooth_connected" : "bluetooth"
            iconColor: root.btConnected > 0 ? Theme.cyan : Theme.text
            onClicked: Shell.toggle("control")
        }
        // volume: icon + percentage form ONE scroll target (hover + wheel = ±5% per notch)
        Item {
            id: volBox
            width: vol.implicitWidth + 4; height: 30

            Rectangle {   // hover highlight for the whole volume control
                anchors.fill: parent
                radius: height / 2
                color: volHover.hovered ? Theme.chip : "transparent"
                Behavior on color { CAnim {} }
            }

            Row {
                id: vol
                anchors.verticalCenter: parent.verticalCenter
                IconBtn {
                    size: 30
                    icon: Audio.icon
                    iconColor: Audio.muted ? Theme.red : Theme.text
                    active: Shell.panel === "audio"
                    onClicked: Shell.toggleAudio(volBox)                         // drop down the audio panel
                    onRightClicked: Quickshell.execDetached(["pwvucontrol"])
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Audio.volume * 100) + "%"
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    rightPadding: 6
                    color: Audio.muted ? Theme.red : Theme.text
                    // clicking the percentage also drops the panel down (the icon has its own click)
                    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: Shell.toggleAudio(volBox) }
                }
            }

            HoverHandler { id: volHover; cursorShape: Qt.PointingHandCursor }
            // middle-click anywhere on the volume control = mute
            TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: Audio.toggleMute() }

            // mouse wheels send ±120 per notch; touchpads / smooth wheels send many small deltas,
            // so accumulate and step 5% per full notch
            property real acc: 0
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: e => {
                    const d = e.angleDelta.y !== 0 ? e.angleDelta.y : e.pixelDelta.y * 4;
                    volBox.acc += d;
                    const steps = volBox.acc > 0 ? Math.floor(volBox.acc / 120) : Math.ceil(volBox.acc / 120);
                    if (steps !== 0) {
                        volBox.acc -= steps * 120;
                        Audio.setVolume(Math.round((Audio.volume + steps * 0.05) * 20) / 20);
                    }
                }
            }
        }
        Item {
            width: 30; height: 30
            IconBtn {
                id: bell
                anchors.fill: parent
                icon: Shell.dnd ? "notifications_off" : Notifs.unseen > 0 ? "notifications_unread" : "notifications"
                onClicked: Shell.toggle("control")
                transform: Rotation { id: wig; origin.x: 15; origin.y: 4; angle: 0 }
            }
            Rectangle {
                visible: Notifs.unseen > 0
                anchors.right: parent.right
                anchors.top: parent.top
                width: Math.max(15, cnt.implicitWidth + 6); height: 15; radius: 8
                color: Theme.red
                scale: visible ? 1 : 0
                Behavior on scale { Anim { easing.type: Theme.springy } }
                Txt { id: cnt; anchors.centerIn: parent; text: Notifs.unseen > 9 ? "9+" : Notifs.unseen; font.pixelSize: 9; font.weight: Font.Black; color: "#1a0005" }
            }
            Connections {
                target: Notifs
                function onArrived() { wiggle.restart(); }
            }
            SequentialAnimation {
                id: wiggle
                loops: 2
                NumberAnimation { target: wig; property: "angle"; to: 18; duration: 70 }
                NumberAnimation { target: wig; property: "angle"; to: -18; duration: 120 }
                NumberAnimation { target: wig; property: "angle"; to: 0; duration: 70 }
            }
        }
    }
}
