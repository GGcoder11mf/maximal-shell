# Maximal Shell

> *README written by Claude, while the real code is written and debugged by me — sorry, I'm a lazy bum (;>)*

![Maximal Shell desktop](assets/desktop-digital.webp)

A maximalist, music-focused **Hyprland** rice with a fully custom **Quickshell** desktop shell —
everything animated, everything themed from your wallpaper (or the album art of what's playing),
and the whole desktop reacting to music.

## Highlights
- **Wallpaper → theme everywhere** (matugen): shell, window borders, terminals (foot), Qt/KDE apps, launcher,
  lock screen. Wallpaper picker (cover-flow) + `>wallpaper` live-preview grid in the launcher.
- **Music-focused**: album-art theming, synced lyrics, now-playing desktop card, track-change toasts,
  full-screen **Music Stage** (auto-opens when idle), audio-reactive palette / glows / borders with an
  intensity slider and mood profiles (auto · chill · groove · hype).
- **Animated everything**: spring physics, spinning gradient borders, a desktop clock that *wraps its digits
  into an analog dial*, workspace OSD, staggered panels — tuned to stay smooth (see perf rules below).
- **Practical**: launcher with `>commands`, `=calc`, `!run`, `?web`; Alt+Tab switcher with live previews;
  window overview; screenshot / recording / colour-picker flyouts (OCR, annotate, inline video preview);
  timers & pomodoro in the bar; audio dropdown with per-app volume; control center; keybind cheatsheet
  (Super + /); game / zen modes; screen shaders (night light, vibrance, CRT…).

## Showcase

| Clock morph — digits wrap into an analog dial | Wallpaper → everything re-themes |
|:---:|:---:|
| ![clock morph](assets/clock-morph.webp) | ![re-theme](assets/retheme.webp) |

![launcher: calculator, commands and the live-preview wallpaper grid](assets/launcher.webp)

| | |
|:---:|:---:|
| ![analog desktop](assets/desktop-analog.webp) **Analog clock** (audio-reactive tick ring) + now-playing card with synced lyrics | ![music stage](assets/stage.webp) **Music Stage** — blurred cover, radial spectrum, scrolling lyrics |
| ![dashboard](assets/dashboard.webp) **Dashboard** — weather, media vinyl with radial visualiser, calendar, system graphs | ![control center](assets/control.webp) **Control center** — toggles, sliders, music intensity + moods |
| ![launcher](assets/launcher-apps.webp) **Launcher** — fuzzy apps with frecency | ![commands](assets/launcher-commands.webp) **`>` commands** |
| ![wallpaper grid](assets/launcher-wallpapers.webp) **`>wallpaper`** — live-preview grid | ![wallpapers](assets/wallpapers.webp) **Wallpaper picker** — cover-flow + palette styles |
| ![windows](assets/windows.webp) **Windows** — spinning gradient borders, themed foot + Dolphin | ![overview](assets/overview.webp) **Overview** — live previews, drag between workspaces |
| ![switcher](assets/switcher.webp) **Alt+Tab switcher** — most-recently-used, live previews | ![audio](assets/audio-dropdown.webp) **Audio dropdown** — devices + per-app volume with live meters |
| ![cheatsheet](assets/cheatsheet.webp) **Keybind cheatsheet** (Super + /) — generated from Hyprland | ![power](assets/power.webp) **Power menu** |
| ![flyout](assets/flyout-and-timer.webp) **Capture flyout** + **timer** in the bar | ![workspace osd](assets/workspace-osd.webp) **Workspace OSD** |

## Install
```sh
git clone https://github.com/GGcoder11mf/maximal-shell ~/.config/hypr/rices/maximal
~/.config/hypr/rices/maximal/install.sh
```
`install.sh` checks dependencies, installs the `rice` switcher, hooks the rice into
`~/.config/hypr/hyprland.lua` (backup kept) and makes it the default at login.

**Requires:** Hyprland ≥ 0.56 with the **Lua** config · quickshell · the `caelestia-shell` QML plugin
(audio visualiser + lyrics services) · matugen · foot · fuzzel · hyprlock · hypridle · grim · slurp ·
wf-recorder · satty · tesseract · hyprpicker · cliphist · playerctl · wireplumber · qalc · imagemagick ·
ffmpeg · Qt6 Multimedia (ffmpeg backend) · fonts: Rubik, Material Symbols Rounded, JetBrainsMono Nerd Font.

**Switching:** `rice <name>` (this session) · `rice default <name>` (at login) · `rice` (status).

## Keys you'll want first
| | |
|---|---|
| tap **Super** | launcher (`>` commands, `=` calc, `!` run, `?` web) |
| **Super + /** | every keybind, searchable |
| **Super + D / N** | dashboard / control center |
| **Alt + Tab** | window switcher (live previews) |
| **Super + Tab** | overview |
| **Super + F11** | Music Stage |
| **Super + Shift + S** | screenshot region |

---

# Developer notes

## Layout
| Path | What |
|---|---|
| `init.lua` | entry point (sets the `MAXI` global) |
| `look.lua` | gaps, blur, glow, shadows, **all animations** (springs, spinning borders) |
| `theme.lua` | colour-dependent settings, re-applied live after a wallpaper change |
| `keybinds.lua` | ~140 binds, each with a `"Category › Description"` label |
| `submaps.lua` | modal keymaps: resize (Super+R), move (Super+Shift+R), launch leader (Super+Y), power chord (Super+Ctrl+Esc) |
| `modes.lua` | custom features: game/zen mode, layout & gap cycling, screen shaders, zoom, scratchpads, toasts |
| `rules.lua` | window / workspace / layer rules |
| `shaders/` | screen effects: night light, vibrance, grayscale, CRT |
| `matugen/` | wallpaper → palette templates (shell, Hyprland, foot, fuzzel, hyprlock) |
| `generated/` | matugen output (don't edit) |
| `scripts/` | start, wallpaper, screenshot, record, clipboard, emoji |
| `shell/` | the Quickshell UI (bar, wallpaper, notifications, OSD, panels…) |

## Launcher (Super)
- plain text → apps (fuzzy + frecency) · `=` calculator (qalc) · `!` shell command (Shift+Enter: in terminal) · `?` web search
- `>` commands — `>wallpaper [filter]` live-preview grid (arrows browse, Enter applies + re-themes, Esc reverts),
  `>scheme` palette style, `>random`, `>gamemode`, `>nightlight`, `>effect`, `>zen`, `>layout`, `>ocr`, `>record`, `>lock`, `>keybinds`…
  Add your own in the `commands` list in `shell/modules/Launcher.qml` (`run`, `panel`, or `sub`).

## Music features (`shell/services/Music.qml`)
- **Album colours** (default on): when a track plays, `scripts/art-theme.sh` themes the whole rice from its
  cover (shell, borders, terminals, Qt, hyprlock); 20 s after the music stops the wallpaper palette returns.
- **Synced lyrics** via Caelestia's `Lyrics` service; YouTube-style titles are cleaned
  ("tameimpalaVEVO · Tame Impala - X (Official Video)" → "Tame Impala · X") before lookup.
- **Now-playing card** on the desktop (bottom-right): art + vinyl, progress, 3-line lyrics. Click → stage.
- **Track toast** under the bar on every track change.
- **Music Stage** (`Super+F11`, `>stage`): full-screen blurred-cover scene, 96-bar radial spectrum around the
  art, scrolling lyrics, controls. Opens by itself after 150 s idle while music plays (`>autostage` to toggle).
- Debug: `… ipc call music stats`

## Practical extras
- **Alt+Tab switcher** (`Switcher.qml`): live previews, most-recently-used order; hold Alt + Tab/Shift+Tab, release
  Alt to switch, Esc cancels. Hyprland binds → `maxi:switcher(Prev)`; the Alt *release* reaches the switcher
  as a key event. Old instant cycle moved to Super+Alt+Tab.
- **Capture flyout** (`CaptureFlyout.qml`): screenshots / recordings / colour picks slide in bottom-right with
  actions. Scripts call `ipc call capture shot|video|color` (notification fallback).
- **Timers** (`services/Timers.qml`, `bar/TimerPill.qml`): `>timer 25m|1h30m|90s|10:00`, `>pomodoro`, `>break`,
  `>stoptimer`; ring in the bar (click = pause, right-click = cancel), burst + chime at the end.
- **Workspace OSD** (`WorkspaceOsd.qml`): big number + window dots on switch (`>wsosd` toggles).

## Audio dropdown (bar)
Click the speaker icon or the percentage → `shell/modules/AudioPopup.qml`: volume + mic sliders, output-device
switching, per-app volume with live level meters (PwNodePeakMonitor). Scroll on the control = ±5 %,
middle-click = mute, right-click = pwvucontrol. Doesn't grab the keyboard; click outside to close.
Gotcha: in Quickshell, playback streams are `isStream && isSink` (capture streams are `isStream && !isSink`),
and `properties` is only populated for tracked nodes — don't filter on `media.class`.

## Audio-reactive desktop
Reacts to **any** sound the system plays (default output monitor) — the *style* reacts, not just bars.
- `shell/services/Viz.qml`: spectrum from Caelestia's `CavaProvider`, band levels, spectral-flux beats,
  `pulse` (1 on a beat → 0), BPM from beat intervals, and `phase` (palette hue drift; returns home on silence).
- `Theme.react()`: accent colours (primary, tertiary, magenta, cyan, containers…) hue-drift with `phase` and
  saturate/brighten on beats → every themed element follows. Glass surfaces tint with loudness.
- Glows: every GlowBorder / GradientText glows while music plays and flares on beats; spinning gradients speed up.
- Wallpaper: zoom on bass, saturation/brightness grading, colour flash on beats. Aura behind the clock.
- Windows: `MAXI.modes.beat()` recolours borders to the shifted palette + glow flash; theme.lua restores on silence.
- Desktop clock (`shell/modules/DesktopClock.qml`): click it / Super+F10 / `>clock` morphs digital ⇄ analog —
  the digits bend along a curve into the dial and become its numerals; the 60 ticks are a radial spectrum.
  Debug: `… ipc call state set clockDebugT 0.5` pins the morph, `… ipc call state snapshot /path.png` renders it.
- Visualizers: only in the dashboard (+ the analog clock's tick ring) (radial ring around the record + media-card equaliser).
- Intensity (control center slider, 0–100 %) scales everything; moods Auto/Chill/Groove/Hype (chips, `>mood`).
  Auto classifies ~8 s of loudness, BPM and beat density and needs 5 s of agreement to switch.
- The palette only sways ±~30° around the wallpaper hue so the shell, wallpaper and apps stay matched;
  window borders are synced to the shell palette (≤4 Hyprland updates/s) and flare modestly on beats.
- Settings persist in `~/.local/state/maximal/settings.json`. `settings.watchFiles` is off on purpose:
  reloading the shell breaks the audio capture → after editing, restart with Super+Ctrl+Alt+R.
- Toggles: Super+F9 / `>reactive` / control-center tile (right-click: beat borders) / `>beatborders`. Off in game mode.
- Rule: never put a Behavior/animation on anything driven by Viz values — it adds visible lag.
- Perf rules (measured): the wallpaper layer must stay still (any change → Hyprland re-blurs every window
  above it); desktop widgets animate only when the workspace has no windows (`win.live`); spinning
  gradients use ONE 20 fps clock (`Theme.spinT`) that only runs while music plays; palette crossfades
  are 12 steps, not 60 fps; Viz analyses at ~30 Hz and publishes the palette at ~7.5 Hz.
- Debug: `qs -p ~/.config/hypr/rices/maximal/shell ipc call viz stats`

## Terminal
- `foot.ini` = your `~/.config/foot/foot.ini` + `generated/foot.ini` colours.
- `~/.config/fish/config.fish` and `functions/fish_greeting.fish` are **rice-aware**: under `maximal` they print
  `generated/sequences.txt` (palette, incl. slots 16–20 used by fastfetch) and `generated/greeting.txt` (gradient banner);
  otherwise Caelestia's originals. Backups: `*.pre-maximal.bak` next to each file.
- `scripts/term-colors.py --push` regenerates both and recolours every open terminal live (run by wallpaper.sh).

## Qt / KDE apps (Dolphin…)
- `qtengine.json` (via `QTENGINE_CONFIG`): colour scheme `generated/maximal.colors` (matugen `kde.colors` template), Darkly style, Rubik / JetBrains Mono, Papirus-Dark.
- `xdg/darklyrc` (via `XDG_CONFIG_DIRS`, only used while `~/.config/darklyrc` doesn't exist): corner radius, tab highlights, animations, transient scrollbars.
  Darkly's own window translucency doesn't take effect here, so the glass look comes from a Hyprland opacity rule in `rules.lua`.
- `rice` resets both env vars when switching to another rice. wallpaper.sh rewrites `qtengine.json` so qtengine's watcher reloads open apps.

## Shell pieces (`shell/`)
- `services/` singletons: `Theme` (animated palette), `Shell` (state + IPC), `Audio`, `Media`, `Sys`, `Notifs`, `Weather`, `Wallpapers`, `Binds`, `Toaster`
- `widgets/` building blocks: `Glass`, `GlowBorder`, `Spectrum`, `GradientText`, `IconBtn`, `Slider`, `Ring`, `Graph`, `Tile`, `Keycap`, `Overlay`…
- `modules/` the UI: `Background`, `bar/`, `Osd`, `Notifications`, `Toasts`, `SubmapHint`, `dashboard/`, `control/`, `Launcher`, `PowerMenu`, `Cheatsheet`, `WallpaperPicker`, `Overview`

## Developing
- Soft reload (keeps the old config if the new one fails): `qs -p ~/.config/hypr/rices/maximal/shell ipc call state reload`
- Logs: `qs -p ~/.config/hypr/rices/maximal/shell log`
- IPC: `… ipc call state toggle launcher|dashboard|control|power|cheatsheet|wallpapers|overview`, `… ipc call toast pop "Title" "Body" "icon"`
- Lua live: `hyprctl eval 'MAXI.modes.toggle_game()'`
- Gotchas learned the hard way: no `Behavior` inside a singleton (Qt segfault); don't name properties `top/left/…` (FINAL); `State` is a QtQuick type (ours is `Shell`); IPC function names can't be `show`/`get`.

## Ideas for later
cava for a real audio visualizer · Wi-Fi network picker · per-app volume mixer · clipboard/emoji in the Quickshell launcher · ydotoold service (emoji auto-typing) · btop/GTK theming from matugen
