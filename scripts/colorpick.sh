#!/usr/bin/env bash
# colorpick.sh — pick a colour; the shell shows a swatch with HEX/RGB/HSL (HEX already copied)
hex="$(hyprpicker -f hex 2>/dev/null)" || exit 0
[ -n "$hex" ] || exit 0
qs -p "$HOME/.config/hypr/rices/maximal/shell" ipc call capture color "$hex" 2>/dev/null \
    || { printf %s "$hex" | wl-copy; notify-send -a "Colour picker" "$hex" "copied to clipboard"; }
