hl.env("XCURSOR_THEME", "sweet-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
hl.env("QTENGINE_CONFIG", os.getenv("HOME") .. "/.config/hypr/rices/maximal/qtengine.json") -- Dolphin & co. use the rice palette
hl.env("XDG_CONFIG_DIRS", os.getenv("HOME") .. "/.config/hypr/rices/maximal/xdg:/etc/xdg") -- rice darklyrc (glassy Dolphin)
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
