#!/usr/bin/env python3
"""Build terminal colour escape sequences + a gradient greeting from the matugen palette.

Writes  generated/sequences.txt  (OSC codes: fg/bg/cursor/selection/16-colour palette)
        generated/greeting.txt   (MAXIMAL banner, truecolor gradient)
With --push, also writes the sequences to every open terminal (live recolour).
"""
import glob, json, os, re, sys

R = os.path.expanduser("~/.config/hypr/rices/maximal")
G = os.path.join(R, "generated")

foot = open(os.path.join(G, "foot.ini")).read()
kv = dict(re.findall(r"^([\w-]+)=([0-9a-fA-F]{6})\b", foot, re.M))
pal = json.load(open(os.path.join(G, "colors.json")))


def rgb(h):
    h = h.lstrip("#")
    return f"rgb:{h[0:2]}/{h[2:4]}/{h[4:6]}"


seq = []
seq.append(f"\033]10;{rgb(kv['foreground'])}\033\\")
seq.append(f"\033]11;{rgb(kv['background'])}\033\\")
seq.append(f"\033]12;{rgb(pal['primary'])}\033\\")
seq.append(f"\033]17;{rgb(kv['selection-background'])}\033\\")
seq.append(f"\033]19;{rgb(kv['selection-foreground'])}\033\\")
for i in range(8):
    seq.append(f"\033]4;{i};{rgb(kv[f'regular{i}'])}\033\\")
    seq.append(f"\033]4;{i + 8};{rgb(kv[f'bright{i}'])}\033\\")
# Extended slots used by your fastfetch config / greeting (Caelestia convention):
# 16 primary · 17 secondary · 18 tertiary  (+ 19 magenta · 20 cyan for extras)
for i, k in enumerate(["primary", "secondary", "tertiary", "magenta", "cyan"]):
    seq.append(f"\033]4;{16 + i};{rgb(pal[k])}\033\\")
sequences = "".join(seq)
open(os.path.join(G, "sequences.txt"), "w").write(sequences)

# ── greeting banner: horizontal gradient primary -> tertiary -> magenta ──
banner = [
    "  ███╗   ███╗ █████╗ ██╗  ██╗██╗███╗   ███╗ █████╗ ██╗     ",
    "  ████╗ ████║██╔══██╗╚██╗██╔╝██║████╗ ████║██╔══██╗██║     ",
    "  ██╔████╔██║███████║ ╚███╔╝ ██║██╔████╔██║███████║██║     ",
    "  ██║╚██╔╝██║██╔══██║ ██╔██╗ ██║██║╚██╔╝██║██╔══██║██║     ",
    "  ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗██║██║ ╚═╝ ██║██║  ██║███████╗",
    "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝",
]
stops = [pal["primary"], pal["tertiary"], pal["magenta"], pal["cyan"]]


def hex2t(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


stops = [hex2t(s) for s in stops]


def at(t):
    t = max(0.0, min(1.0, t)) * (len(stops) - 1)
    i = min(int(t), len(stops) - 2)
    f = t - i
    a, b = stops[i], stops[i + 1]
    return tuple(round(a[k] + (b[k] - a[k]) * f) for k in range(3))


out = []
w = max(len(l) for l in banner)
for row, line in enumerate(banner):
    s = ""
    for col, ch in enumerate(line):
        if ch == " ":
            s += ch
            continue
        r, g, b = at((col + row * 2) / (w + 10))
        s += f"\033[38;2;{r};{g};{b}m{ch}"
    out.append(s + "\033[0m")
open(os.path.join(G, "greeting.txt"), "w").write("\n".join(out) + "\n")

# ── live push to open terminals ──
if "--push" in sys.argv:
    uid = os.getuid()
    for pts in glob.glob("/dev/pts/[0-9]*"):
        try:
            if os.stat(pts).st_uid != uid:
                continue
            with open(pts, "w") as f:
                f.write(sequences)
        except OSError:
            pass
