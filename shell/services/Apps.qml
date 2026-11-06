pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// App identity helpers (icon / name for a window class or app id).
// Never fuzzy-match an empty string — DesktopEntries.heuristicLookup("") returns an arbitrary
// "best" entry (that's how Firefox once showed up as "KDE Connect SMS"). Exact ids first.
Singleton {
    id: root

    // live app id of a Hyprland toplevel: Wayland appId first, Hyprland's cached IPC class as fallback
    function classOf(t: HyprlandToplevel): string {
        return t?.wayland?.appId || t?.lastIpcObject?.class || t?.lastIpcObject?.initialClass || "";
    }

    function entry(id: string): DesktopEntry {
        const s = (id ?? "").trim();
        if (!s) return null;
        return DesktopEntries.byId(s)
            ?? DesktopEntries.byId(s.toLowerCase())
            ?? DesktopEntries.byId(s.split(".").pop().toLowerCase())     // org.kde.dolphin -> dolphin
            ?? DesktopEntries.heuristicLookup(s);
    }

    function icon(id: string, fallback: string): string {
        const fb = fallback || "application-x-executable";
        const s = (id ?? "").trim();
        if (!s) return Quickshell.iconPath(fb);
        return Quickshell.iconPath(entry(s)?.icon ?? s.toLowerCase(), fb);
    }

    function name(id: string): string {
        const s = (id ?? "").trim();
        return s ? (entry(s)?.name ?? s) : "";
    }
}
