pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Small transient toasts. IPC: qs -p <shell> ipc call toast pop "Title" "Body" "icon"
Singleton {
    id: root
    property list<var> items: []
    property int _id: 0

    function show(title: string, body: string, icon: string): void {
        const t = { id: ++_id, title, body, icon: icon || "info" };
        items = [...items, t].slice(-3);
        kill.createObject(root, { tid: t.id });
    }
    function drop(id: int): void { items = items.filter(t => t.id !== id); }

    Component {
        id: kill
        Timer {
            property int tid
            interval: 2600; running: true
            onTriggered: { root.drop(tid); destroy(); }
        }
    }

    IpcHandler {
        target: "toast"
        function pop(title: string, body: string, icon: string): void { root.show(title, body, icon); }
    }
}
