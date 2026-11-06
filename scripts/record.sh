#!/usr/bin/env bash
# record.sh [region] [mic|silent]  — toggles: run again to stop.
#   (default: whole screen + desktop audio)
# The shell watches ~/.cache/maximal/recording to show the pulsing REC badge.
flag="$HOME/.cache/maximal/recording"
dir="$HOME/Videos/Recordings"; mkdir -p "$dir"

if pgrep -x wf-recorder >/dev/null; then
    pkill -INT -x wf-recorder
    # wait until wf-recorder has exited (= the mp4 is finalised), max ~5 s
    for _ in $(seq 50); do pgrep -x wf-recorder >/dev/null || break; sleep 0.1; done
    last="$(cat "$flag" 2>/dev/null)"; rm -f "$flag"
    # poster frame for the flyout
    poster="$HOME/.cache/maximal/rec-poster.png"
    ffmpeg -y -loglevel error -ss 0.3 -i "$last" -frames:v 1 -vf scale=760:-2 "$poster" 2>/dev/null \
        || ffmpeg -y -loglevel error -i "$last" -frames:v 1 -vf scale=760:-2 "$poster" 2>/dev/null
    qs -p "$HOME/.config/hypr/rices/maximal/shell" ipc call capture video "$last" "$poster" 2>/dev/null && exit 0
    act="$(notify-send -a Recorder -i media-record -A open=Play -A folder=Folder "Recording saved" "$(basename "$last")")"
    case "$act" in open) xdg-open "$last" ;; folder) thunar "$dir" ;; esac
    exit 0
fi

file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
args=(-f "$file")

# words in $*: region (pick an area) · mic (record the microphone instead of desktop audio) · silent (no audio)
# default = whole screen + desktop audio (what you hear)
modes=" $* "
if [[ "$modes" == *" region "* ]]; then
    g="$(slurp -d -b '#00000088' -c '#ff3d6ecc' -w 2)" || exit 0
    args+=(-g "$g")
fi
if [[ "$modes" == *" silent "* ]]; then
    what="no audio"
elif [[ "$modes" == *" mic "* ]]; then
    args+=(--audio="$(pactl get-default-source)"); what="microphone"
else
    args+=(--audio="$(pactl get-default-sink).monitor"); what="desktop audio"
fi

echo "$file" > "$flag"
notify-send -a Recorder -i media-record -t 1800 "Recording started · $what" "Press the same key again to stop"
wf-recorder "${args[@]}" >/dev/null 2>&1
rm -f "$flag"
