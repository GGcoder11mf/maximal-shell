#!/usr/bin/env bash
# art-theme.sh <art-url|path>   — re-theme the whole rice from a track's cover art
# art-theme.sh --restore        — back to the wallpaper's palette
# Called by the shell (services/Music.qml) on track changes. Live-applies like wallpaper.sh:
# shell palette (colors.json), window borders, terminals, Qt apps, fuzzel, hyprlock.
set -u
R="$HOME/.config/hypr/rices/maximal"
ST="$HOME/.local/state/maximal"
CACHE="$HOME/.cache/maximal/art"; mkdir -p "$CACHE"

if [ "${1:-}" = "--restore" ]; then
    exec "$R/scripts/wallpaper.sh" --reapply >/dev/null
fi

src="${1:-}"
[ -n "$src" ] || exit 1
case "$src" in
    file://*) img="${src#file://}"; img="$(printf '%b' "${img//%/\\x}")" ;;   # url-decode
    http://*|https://*)
        img="$CACHE/$(printf '%s' "$src" | md5sum | cut -c1-16).img"
        [ -s "$img" ] || curl -sfL --max-time 10 -o "$img" "$src" || exit 1 ;;
    *) img="$src" ;;
esac
[ -s "$img" ] || exit 1

scheme="$(cat "$ST/scheme" 2>/dev/null)"; scheme="${scheme:-scheme-vibrant}"
sed "s|@R@|$R|g" "$R/matugen/config.toml" > "$HOME/.cache/maximal/matugen.toml"
matugen image "$img" -c "$HOME/.cache/maximal/matugen.toml" -m dark -t "$scheme" \
    --source-color-index 0 -q 2>/dev/null || exit 1

# same live-apply steps as wallpaper.sh
python3 -I "$R/scripts/term-colors.py" --push 2>/dev/null
[ -f "$R/qtengine.json" ] && { c="$(cat "$R/qtengine.json")"; printf '%s\n' "$c" > "$R/qtengine.json"; }
hyprctl eval "dofile('$R/theme.lua')" >/dev/null 2>&1
echo "themed from: $img"
