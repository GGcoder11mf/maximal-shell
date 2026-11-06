#!/usr/bin/env bash
# Maximal Shell installer. Expects this repo at ~/.config/hypr/rices/maximal
#   git clone https://github.com/GGcoder11mf/maximal-shell ~/.config/hypr/rices/maximal && ~/.config/hypr/rices/maximal/install.sh
set -e
R="$HOME/.config/hypr/rices/maximal"
[ "$(cd "$(dirname "$0")" && pwd)" = "$R" ] || { echo "Clone this repo to $R first." >&2; exit 1; }

echo ":: checking dependencies"
missing=()
for c in Hyprland qs matugen foot fuzzel hyprlock hypridle grim slurp wf-recorder satty tesseract hyprpicker \
         cliphist wl-copy playerctl wpctl pactl qalc magick ffmpeg curl jq python3; do
    command -v "$c" >/dev/null || missing+=("$c")
done
[ -d /usr/lib/qt6/qml/Caelestia ] || missing+=("caelestia-shell (QML plugin: audio visualiser + lyrics)")
for f in "Rubik" "Material Symbols Rounded" "JetBrainsMono Nerd Font"; do
    fc-list : family | grep -qi "$f" || missing+=("font: $f")
done
if [ ${#missing[@]} -gt 0 ]; then
    printf '   missing: %s\n' "${missing[@]}"
    echo "   (install them, then re-run; continuing anyway)"
fi

echo ":: installing the 'rice' switcher -> ~/.local/bin/rice"
install -Dm755 "$R/extras/rice" "$HOME/.local/bin/rice"

echo ":: hooking the rice into ~/.config/hypr/hyprland.lua"
H="$HOME/.config/hypr/hyprland.lua"
if [ -f "$H" ] && grep -q "Rice switcher" "$H"; then
    echo "   already hooked"
else
    [ -f "$H" ] && cp -a "$H" "$H.pre-maximal.bak" && echo "   backup: $H.pre-maximal.bak"
    { cat "$R/extras/hyprland-switcher.lua"; [ -f "$H.pre-maximal.bak" ] && cat "$H.pre-maximal.bak"; } > "$H"
fi

echo ":: making maximal the default rice at login"
echo maximal > "$HOME/.config/hypr/rices/default"
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings"

echo ":: done. Put some wallpapers in ~/Pictures/Wallpapers, then log out/in or run:  rice maximal"
echo "   optional: fish greeting/colours in $R/extras/fish/"
