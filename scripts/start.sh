#!/usr/bin/env bash
# (Re)start every component of the maximal rice. Safe to run repeatedly.
R="$HOME/.config/hypr/rices/maximal"
ST="$HOME/.local/state/maximal"
mkdir -p "$ST" "$HOME/.cache/maximal"

# Other shells / rices off
qs -c caelestia kill >/dev/null 2>&1
pkill -f "waybar -c $HOME/.config/hypr/rices/" ; pkill -x mako ; pkill -x swaybg
pkill -f "hypridle -c $HOME/.config/hypr/rices/"
qs -p "$R/shell" kill >/dev/null 2>&1
for _ in $(seq 30); do pgrep -f "qs (-c caelestia|-p $R/shell)" >/dev/null || break; sleep 0.1; done
# a frozen shell can't answer "kill" over IPC -> force it (also frees any stuck keyboard grab)
pgrep -f "^qs -p $R/shell" >/dev/null && pkill -9 -f "^qs -p $R/shell"

# First run: generate a palette from the current wallpaper
[ -f "$R/generated/colors.json" ] || "$R/scripts/wallpaper.sh" --reapply >/dev/null

# Session essentials (only if missing)
pgrep -f polkit-gnome-authentication-agent-1 >/dev/null || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep -f "wl-paste --type text"  >/dev/null || wl-paste --type text  --watch cliphist store &
pgrep -f "wl-paste --type image" >/dev/null || wl-paste --type image --watch cliphist store &
pgrep -x gnome-keyring-d >/dev/null || gnome-keyring-daemon --start --components=secrets >/dev/null 2>&1 &
pgrep -x mpris-proxy >/dev/null || mpris-proxy >/dev/null 2>&1 &

# Qt theme config needs absolute paths -> render it from the template for this $HOME
sed "s|@R@|$R|g" "$R/qtengine.json.in" > "$R/qtengine.json"

# Cursor theme (what Caelestia's startup used to do)
hyprctl setcursor sweet-cursors 24 >/dev/null 2>&1
gsettings set org.gnome.desktop.interface cursor-theme sweet-cursors 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null

# Qt apps launched from the shell (launcher, buttons) get the rice's Qt theme
export QT_QPA_PLATFORMTHEME=qtengine QTENGINE_CONFIG="$R/qtengine.json" XDG_CONFIG_DIRS="$R/xdg:/etc/xdg"

# The shell (bar, wallpaper, notifications, OSD, panels…) + idle daemon
qs -p "$R/shell" -d >/dev/null 2>&1
hypridle -c "$R/hypridle.conf" >/dev/null 2>&1 &
disown -a
