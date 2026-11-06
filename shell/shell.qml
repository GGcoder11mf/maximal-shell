//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// MAXIMAL shell — Quickshell config for the "maximal" Hyprland rice.
import QtQuick
import Quickshell
import "modules"
import "modules/bar"
import "modules/dashboard"
import "modules/control"

ShellRoot {
    settings.watchFiles: false   // no auto hot-reload: a reload breaks the audio capture (restart instead)

    Shortcuts {}
    Background {}
    Bar {}
    Osd {}
    Notifications {}
    Toasts {}
    SubmapHint {}
    Dashboard {}
    ControlCenter {}
    AudioPopup {}
    TrackToast {}
    Stage {}
    Switcher {}
    CaptureFlyout {}
    WorkspaceOsd {}
    Launcher {}
    PowerMenu {}
    Cheatsheet {}
    WallpaperPicker {}
    Overview {}
}
