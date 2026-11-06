#!/usr/bin/env bash
# wallpaper.sh [PATH | --random | --next | --prev | --reapply] [--scheme TYPE | --cycle-scheme]
# Sets the wallpaper, regenerates the whole palette with matugen and applies it live.
set -u
R="$HOME/.config/hypr/rices/maximal"
ST="$HOME/.local/state/maximal"; mkdir -p "$ST" "$HOME/.cache/maximal/thumbs"
DIR="$HOME/Pictures/Wallpapers"
SCHEMES=(scheme-vibrant scheme-expressive scheme-fruit-salad scheme-rainbow scheme-tonal-spot scheme-content scheme-fidelity scheme-monochrome)

cur="$(cat "$ST/wallpaper" 2>/dev/null)"
[ -f "$cur" ] || cur="$(readlink -f "$HOME/.local/state/caelestia/wallpaper/current" 2>/dev/null)"
[ -f "$cur" ] || cur="$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)"
scheme="$(cat "$ST/scheme" 2>/dev/null)"; scheme="${scheme:-scheme-vibrant}"
mapfile -t walls < <(find "$DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)

idx_of() { local i; for i in "${!walls[@]}"; do [ "${walls[$i]}" = "$1" ] && { echo "$i"; return; }; done; echo 0; }

new="$cur"
while [ $# -gt 0 ]; do
    case "$1" in
        --random)   new="${walls[RANDOM % ${#walls[@]}]}"; [ "$new" = "$cur" ] && new="${walls[RANDOM % ${#walls[@]}]}" ;;
        --next)     i=$(idx_of "$cur"); new="${walls[(i + 1) % ${#walls[@]}]}" ;;
        --prev)     i=$(idx_of "$cur"); new="${walls[(i - 1 + ${#walls[@]}) % ${#walls[@]}]}" ;;
        --reapply)  ;;
        --scheme)   scheme="$2"; shift ;;
        --cycle-scheme)
            for i in "${!SCHEMES[@]}"; do [ "${SCHEMES[$i]}" = "$scheme" ] && break; done
            scheme="${SCHEMES[(i + 1) % ${#SCHEMES[@]}]}" ;;
        *)          new="$(readlink -f "$1")" ;;
    esac
    shift
done
[ -f "$new" ] || { echo "no wallpaper found" >&2; exit 1; }

# 1. wallpaper first -> shell starts its transition immediately
echo "$new" > "$ST/wallpaper"
echo "$scheme" > "$ST/scheme"

# 2. palette
sed "s|@R@|$R|g" "$R/matugen/config.toml" > "$HOME/.cache/maximal/matugen.toml"
matugen image "$new" -c "$HOME/.cache/maximal/matugen.toml" -m dark -t "$scheme" \
    --source-color-index 0 -q 2>/dev/null

# 2b. terminal colours + greeting, pushed live into open terminals
python3 -I "$R/scripts/term-colors.py" --push 2>/dev/null

# 2c. poke qtengine's file watcher so open Qt apps (Dolphin…) re-read the new KDE scheme
[ -f "$R/qtengine.json" ] && { c="$(cat "$R/qtengine.json")"; printf '%s\n' "$c" > "$R/qtengine.json"; }

# 3. live-apply window border colours
hyprctl eval "dofile('$R/theme.lua')" >/dev/null 2>&1

# 4. thumbnails for the picker (background, only missing ones)
(
    for w in "${walls[@]}"; do
        t="$HOME/.cache/maximal/thumbs/$(basename "${w%.*}").jpg"
        [ -f "$t" ] || magick "$w" -thumbnail 520x320^ -gravity center -extent 520x320 -quality 85 "$t" 2>/dev/null
    done
) &
disown
echo "$new ($scheme)"
