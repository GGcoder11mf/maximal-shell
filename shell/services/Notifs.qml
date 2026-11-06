pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. `all` = history (newest first), `popups` = currently on screen.
Singleton {
    id: root

    property list<QtObject> all: []
    readonly property list<QtObject> popups: all.filter(n => n.popup)
    readonly property int count: all.length
    property int unseen: 0
    signal arrived(QtObject n)

    function clear(): void {
        for (const n of all.slice()) n.notification?.dismiss();
        all = [];
        unseen = 0;
    }
    function dismissNewest(): void {
        const p = popups[0];
        if (p) p.popup = false;
    }
    function remove(n: QtObject): void { all = all.filter(x => x !== n); }

    component Entry: QtObject {
        id: entry
        required property Notification notification
        property bool popup: true
        readonly property date time: new Date()
        readonly property string appName: notification?.appName ?? ""
        readonly property string appIcon: notification?.appIcon ?? ""
        readonly property string summary: notification?.summary ?? ""
        readonly property string body: notification?.body ?? ""
        readonly property string image: notification?.image ?? ""
        readonly property int urgency: notification?.urgency ?? NotificationUrgency.Normal
        readonly property var actions: notification?.actions ?? []
        readonly property int timeout: urgency === NotificationUrgency.Critical ? 0
            : (notification?.expireTimeout > 0 ? notification.expireTimeout : 6000)

        property Connections conn: Connections {
            target: entry.notification
            function onClosed(): void { root.remove(entry); }
        }
    }

    Component { id: entryComp; Entry {} }

    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const e = entryComp.createObject(root, { notification: n });
            e.popup = !Shell.dnd || n.urgency === NotificationUrgency.Critical;
            root.all = [e, ...root.all].slice(0, 80);
            if (Shell.panel !== "control") root.unseen++;
            root.arrived(e);
        }
    }
}
