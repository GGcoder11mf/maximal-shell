#!/usr/bin/env bash
# clipboard.sh [delete|wipe]
cfg="$HOME/.config/hypr/rices/maximal/generated/fuzzel.ini"
pkill -x fuzzel && exit 0
case "$1" in
    delete) cliphist list | fuzzel --config "$cfg" --dmenu --prompt "✕ delete  " | cliphist delete ;;
    wipe)   cliphist wipe && notify-send -a Clipboard -i edit-clear "Clipboard history wiped" ;;
    *)      sel="$(cliphist list | fuzzel --config "$cfg" --dmenu --prompt "󰅌  ")" || exit 0
            printf '%s' "$sel" | cliphist decode | wl-copy ;;
esac
