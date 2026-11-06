pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: Theme.home + "/Pictures/Wallpapers"
    readonly property string thumbs: Theme.home + "/.cache/maximal/thumbs"
    property list<string> list: []
    property string current: ""
    property string preview: ""                      // temporary (launcher >wallpaper); "" = none
    readonly property string shown: preview || current
    property string scheme: "scheme-vibrant"

    function thumb(path: string): string {
        const base = path.split("/").pop().replace(/\.[^.]+$/, "");
        return "file://" + thumbs + "/" + base + ".jpg";
    }
    function set(path: string): void {
        current = path;          // optimistic, so clearing a preview doesn't flash the old one
        preview = "";
        Quickshell.execDetached([Theme.scripts + "wallpaper.sh", path]);
    }
    function setScheme(s: string): void { Quickshell.execDetached([Theme.scripts + "wallpaper.sh", "--reapply", "--scheme", s]); }
    function refresh(): void { lister.running = true; }

    FileView {
        path: Theme.home + "/.local/state/maximal/wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = text().trim()
    }
    FileView {
        path: Theme.home + "/.local/state/maximal/scheme"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.scheme = text().trim() || "scheme-vibrant"
    }

    Process {
        id: lister
        running: true
        command: ["sh", "-c", `find "${root.dir}" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort`]
        stdout: StdioCollector { onStreamFinished: root.list = text.trim().split("\n").filter(s => s.length) }
    }
}
