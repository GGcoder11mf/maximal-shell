#!/usr/bin/env bash
# screenshot.sh full|region|freeze|window|edit|ocr
dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
mode="${1:-full}"

freeze() { hyprpicker -r -z >/dev/null 2>&1 & FPID=$!; sleep 0.15; }
unfreeze() { [ -n "${FPID:-}" ] && kill "$FPID" 2>/dev/null; }
region() { slurp -d -b '#00000088' -c '#ffffffcc' -w 2; }

case "$mode" in
    full)   grim "$file" ;;
    region) g="$(region)" || exit 0; grim -g "$g" "$file" ;;
    freeze) freeze; g="$(region)"; r=$?; [ $r -eq 0 ] && grim -g "$g" "$file"; unfreeze; [ $r -eq 0 ] || exit 0 ;;
    window)
        g="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        grim -g "$g" "$file" ;;
    edit)   freeze; g="$(region)"; r=$?; unfreeze; [ $r -eq 0 ] || exit 0
            grim -g "$g" - | satty --filename - --output-filename "$file" --copy-command wl-copy --early-exit
            exit 0 ;;
    ocr)    freeze; g="$(region)"; r=$?; unfreeze; [ $r -eq 0 ] || exit 0
            text="$(grim -g "$g" - | tesseract stdin stdout 2>/dev/null)"
            printf '%s' "$text" | wl-copy
            notify-send -a "OCR" -i accessories-text-editor "Text copied" "$(printf '%s' "$text" | head -c 180)"
            exit 0 ;;
esac

[ -f "$file" ] || exit 1
wl-copy < "$file"
# animated flyout in the shell (thumbnail + Copy/Edit/Open/Folder/Delete); notification as fallback
qs -p "$HOME/.config/hypr/rices/maximal/shell" ipc call capture shot "$file" 2>/dev/null && exit 0
action="$(notify-send -a Screenshot -i "$file" -A open=Open -A edit=Edit -A folder=Folder \
    "Screenshot captured" "$(basename "$file") · copied to clipboard")"
case "$action" in
    open)   xdg-open "$file" ;;
    edit)   satty --filename "$file" --output-filename "$file" --copy-command wl-copy ;;
    folder) thunar "$dir" ;;
esac
