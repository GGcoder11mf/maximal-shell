#!/usr/bin/env bash
# emoji.sh — fuzzy emoji picker; copies the emoji and types it into the focused window.
cfg="$HOME/.config/hypr/rices/maximal/generated/fuzzel.ini"
list="$HOME/.cache/maximal/emoji.txt"
pkill -x fuzzel && exit 0

if [ ! -s "$list" ]; then
    python3 -I - "$list" <<'EOF'
import sys, unicodedata
ranges = [(0x1F300, 0x1F5FF), (0x1F600, 0x1F64F), (0x1F680, 0x1F6FF), (0x1F900, 0x1F9FF),
          (0x1FA70, 0x1FAFF), (0x2600, 0x26FF), (0x2700, 0x27BF), (0x1F1E6, 0x1F1FF)]
with open(sys.argv[1], "w") as f:
    for a, b in ranges:
        for cp in range(a, b + 1):
            try:
                f.write(f"{chr(cp)}  {unicodedata.name(chr(cp)).lower()}\n")
            except ValueError:
                pass
EOF
fi

sel="$(fuzzel --config "$cfg" --dmenu --prompt "☺  " --width 40 < "$list")" || exit 0
e="${sel%% *}"
printf '%s' "$e" | wl-copy
sleep 0.15
ydotool type -d 1 "$e" >/dev/null 2>&1 || true
