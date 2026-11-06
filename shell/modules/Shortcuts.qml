import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Hyprland global shortcuts: hl.dsp.global("maxi:<name>")
Scope {
    component Sc: GlobalShortcut { appid: "maxi" }

    Sc { name: "launcher";    description: "App launcher";      onPressed: Shell.toggle("launcher") }
    // Tap-Super is a *release* bind: Hyprland only sends "released" for it
    Sc { name: "launcherTap"; description: "App launcher (tap Super)"; onReleased: Shell.toggle("launcher") }
    Sc { name: "dashboard";   description: "Dashboard";         onPressed: Shell.toggle("dashboard") }
    Sc { name: "control";     description: "Control center";    onPressed: Shell.toggle("control") }
    Sc { name: "power";       description: "Power menu";        onPressed: Shell.toggle("power") }
    Sc { name: "cheatsheet";  description: "Keybind cheatsheet"; onPressed: Shell.toggle("cheatsheet") }
    Sc { name: "wallpapers";  description: "Wallpaper picker";  onPressed: Shell.toggle("wallpapers") }
    Sc { name: "overview";    description: "Window overview";   onPressed: Shell.toggle("overview") }
    Sc { name: "bar";         description: "Toggle bar";        onPressed: Shell.barHidden = !Shell.barHidden }
    Sc { name: "clearNotifs"; description: "Clear notifications"; onPressed: Notifs.clear() }
    Sc { name: "dismiss";     description: "Dismiss newest notification"; onPressed: Notifs.dismissNewest() }
    Sc {
        name: "dnd"; description: "Do not disturb"
        onPressed: { Shell.dnd = !Shell.dnd; Toaster.show("Do not disturb", Shell.dnd ? "ON · popups silenced" : "OFF", "do_not_disturb_on"); }
    }
    Sc { name: "switcher"; description: "Window switcher (next)"; onPressed: Shell.switcherStep(1) }
    Sc { name: "switcherPrev"; description: "Window switcher (previous)"; onPressed: Shell.switcherStep(-1) }
    Sc { name: "widgets"; description: "Edit desktop widgets"; onPressed: Widgets.editMode = !Widgets.editMode }
    Sc { name: "stage"; description: "Music Stage"; onPressed: Shell.toggle("stage") }
    Sc {
        name: "clock"; description: "Desktop clock: digital <-> analog"
        onPressed: Shell.analogClock = !Shell.analogClock
    }
    Sc {
        name: "reactive"; description: "Audio-reactive desktop"
        onPressed: { Shell.audioReactive = !Shell.audioReactive; Toaster.show("Audio reactive", Shell.audioReactive ? "ON · the desktop moves with your music" : "OFF", "graphic_eq"); }
    }
    Sc {
        name: "caffeine"; description: "Caffeine"
        onPressed: { Shell.caffeine = !Shell.caffeine; Toaster.show("Caffeine", Shell.caffeine ? "ON · screen stays awake" : "OFF", "coffee"); }
    }
}
