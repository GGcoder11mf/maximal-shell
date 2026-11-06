-- ╔═══════════════════════════════════════════════════════════╗
-- ║  KEYBINDS — every bind has "Category › Description" so the ║
-- ║  cheatsheet (SUPER + /) can list them automatically.       ║
-- ╚═══════════════════════════════════════════════════════════╝
local M   = MAXI.modes
local S   = MAXI.scripts
local mod = "SUPER"

local function b(key, action, desc, flags)
    flags = flags or {}
    flags.description = desc
    hl.bind(key, action, flags)
end
local exec   = hl.dsp.exec_cmd
local global = function(n) return hl.dsp.global("maxi:" .. n) end
local L, LR, R = { locked = true }, { locked = true, repeating = true }, { repeating = true }

local term    = "foot -c " .. MAXI.dir .. "/foot.ini"
local browser = "zen-browser"

-- ── Apps ─────────────────────────────────────────────────────
b(mod .. " + T",              exec(term),                              "Apps › Terminal")
b(mod .. " + Return",         exec(term),                              "Apps › Terminal")
b(mod .. " + SHIFT + Return", exec(term .. " --app-id maxi.float"),    "Apps › Floating terminal")
b(mod .. " + W",              exec(browser),                           "Apps › Browser (Zen)")
b(mod .. " + SHIFT + W",      exec("firefox"),                         "Apps › Browser (Firefox)")
b(mod .. " + E",              exec("thunar"),                          "Apps › File manager")
b(mod .. " + C",              exec("code"),                            "Apps › Code editor")
b(mod .. " + SHIFT + E",      exec(term .. " -e nvim"),                "Apps › Neovim")
b("CTRL + ALT + V",           exec("pwvucontrol"),                     "Apps › Audio mixer")
b(mod .. " + ALT + T",        exec("thunderbird"),                     "Apps › Mail")
b(mod .. " + ALT + O",        exec("obs"),                             "Apps › OBS Studio")

-- ── Shell (Quickshell) ───────────────────────────────────────
b(mod .. " + SUPER_L",        global("launcherTap"),    "Shell › App launcher (tap Super)", { release = true })
b(mod .. " + Space",          global("launcher"),    "Shell › App launcher")
b(mod .. " + D",              global("dashboard"),   "Shell › Dashboard")
b(mod .. " + N",              global("control"),     "Shell › Control center")
b(mod .. " + Slash",          global("cheatsheet"),  "Shell › Keybind cheatsheet")
b(mod .. " + F1",             global("cheatsheet"),  "Shell › Keybind cheatsheet")
b(mod .. " + Escape",         global("power"),       "Shell › Power menu")
b("CTRL + ALT + Delete",      global("power"),       "Shell › Power menu")
b(mod .. " + ALT + W",        global("wallpapers"),  "Shell › Wallpaper picker")
b(mod .. " + Tab",            global("overview"),    "Shell › Window overview")
b(mod .. " + B",              global("bar"),         "Shell › Toggle bar")
b(mod .. " + CTRL + ALT + R", exec(S .. "start.sh"), "Shell › Restart shell")
b(mod .. " + CTRL + SHIFT + R", exec("hyprctl reload"), "Shell › Reload Hyprland")

-- ── Theme / wallpaper ───────────────────────────────────────
b(mod .. " + CTRL + W",       exec(S .. "wallpaper.sh --random"),       "Theme › Random wallpaper")
b(mod .. " + CTRL + Right",   exec(S .. "wallpaper.sh --next"),         "Theme › Next wallpaper")
b(mod .. " + CTRL + Left",    exec(S .. "wallpaper.sh --prev"),         "Theme › Previous wallpaper")
b(mod .. " + CTRL + T",       exec(S .. "wallpaper.sh --cycle-scheme"), "Theme › Cycle colour scheme style")

-- ── Notifications ───────────────────────────────────────────
b("CTRL + ALT + C",           global("clearNotifs"), "Notifications › Clear all", L)
b(mod .. " + ALT + N",        global("dnd"),         "Notifications › Do not disturb")
b(mod .. " + SHIFT + N",      global("dismiss"),     "Notifications › Dismiss newest")

-- ── Windows ─────────────────────────────────────────────────
b(mod .. " + Q",              hl.dsp.window.close(),                               "Windows › Close")
b(mod .. " + SHIFT + Q",      exec("hyprctl kill"),                                "Windows › Kill (click a window)")
b(mod .. " + F",              hl.dsp.window.fullscreen({ mode = "fullscreen" }),   "Windows › Fullscreen")
b(mod .. " + ALT + F",        hl.dsp.window.fullscreen({ mode = "maximized" }),    "Windows › Maximize")
b(mod .. " + ALT + Space",    hl.dsp.window.float({ action = "toggle" }),          "Windows › Toggle floating")
b(mod .. " + ALT + C",        M.float_center(0.6, 0.7),                             "Windows › Float + centre (60%)")
b(mod .. " + CTRL + Backslash", hl.dsp.window.center(),                            "Windows › Centre floating")
b(mod .. " + P",              hl.dsp.window.pin(),                                  "Windows › Pin on all workspaces")
b(mod .. " + ALT + P",        hl.dsp.window.pseudo(),                               "Windows › Pseudo-tile")
b(mod .. " + J",              hl.dsp.layout("togglesplit"),                         "Windows › Toggle split (dwindle)")
b(mod .. " + ALT + J",        hl.dsp.layout("swapsplit"),                           "Windows › Swap split (dwindle)")
b("ALT + TAB",                global("switcher"),                                   "Windows › Switcher (hold Alt, tap Tab)")
b("SHIFT + ALT + TAB",        global("switcherPrev"),                               "Windows › Switcher, backwards")
b(mod .. " + ALT + TAB",      hl.dsp.window.cycle_next(),                           "Windows › Quick cycle (no switcher)", R)
b(mod .. " + mouse:272",      hl.dsp.window.drag(),                                 "Windows › Drag (mouse)", { mouse = true })
b(mod .. " + mouse:273",      hl.dsp.window.resize(),                               "Windows › Resize (mouse)", { mouse = true })
b(mod .. " + Z",              hl.dsp.window.drag(),                                 "Windows › Drag (hold)", { mouse = true })
b(mod .. " + X",              hl.dsp.window.resize(),                               "Windows › Resize (hold)", { mouse = true })

for _, d in ipairs({ { "left", "←" }, { "right", "→" }, { "up", "↑" }, { "down", "↓" } }) do
    b(mod .. " + " .. d[1],                hl.dsp.focus({ direction = d[1] }),       "Focus › Move focus " .. d[2])
    b(mod .. " + SHIFT + " .. d[1],        hl.dsp.window.move({ direction = d[1] }), "Windows › Move window " .. d[2])
    b(mod .. " + CTRL + SHIFT + " .. d[1], hl.dsp.window.swap({ direction = d[1] }), "Windows › Swap window " .. d[2])
end

b(mod .. " + Minus",          hl.dsp.window.resize({ x = -60, y = 0, relative = true }), "Resize › Narrower", R)
b(mod .. " + Equal",          hl.dsp.window.resize({ x = 60, y = 0, relative = true }),  "Resize › Wider", R)
b(mod .. " + SHIFT + Minus",  hl.dsp.window.resize({ x = 0, y = -60, relative = true }), "Resize › Shorter", R)
b(mod .. " + SHIFT + Equal",  hl.dsp.window.resize({ x = 0, y = 60, relative = true }),  "Resize › Taller", R)

-- ── Groups (tabs) ───────────────────────────────────────────
b(mod .. " + G",              hl.dsp.group.toggle(),                         "Groups › Toggle group")
b(mod .. " + Comma",          hl.dsp.group.prev(),                           "Groups › Previous tab")
b(mod .. " + Period",         hl.dsp.group.next(),                           "Groups › Next tab")
b(mod .. " + U",              hl.dsp.window.move({ out_of_group = true }),   "Groups › Pop window out")
b(mod .. " + SHIFT + G",      hl.dsp.group.lock_active(),                    "Groups › Lock group")

-- ── Workspaces ──────────────────────────────────────────────
for i = 1, 10 do
    local k = i % 10
    b(mod .. " + " .. k,              hl.dsp.focus({ workspace = i }),                      "Workspaces › Go to " .. i)
    b(mod .. " + ALT + " .. k,        hl.dsp.window.move({ workspace = i }),                "Workspaces › Move window to " .. i)
    b(mod .. " + SHIFT + " .. k,      hl.dsp.window.move({ workspace = i, follow = false }), "Workspaces › Send window silently to " .. i)
end
b(mod .. " + grave",          hl.dsp.focus({ workspace = "previous" }), "Workspaces › Previous workspace")
b(mod .. " + mouse_down",     hl.dsp.focus({ workspace = "e+1" }),      "Workspaces › Next (scroll)")
b(mod .. " + mouse_up",       hl.dsp.focus({ workspace = "e-1" }),      "Workspaces › Previous (scroll)")
b(mod .. " + Page_Down",      hl.dsp.focus({ workspace = "+1" }),       "Workspaces › Next", R)
b(mod .. " + Page_Up",        hl.dsp.focus({ workspace = "-1" }),       "Workspaces › Previous", R)
b(mod .. " + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), "Workspaces › Move window next")
b(mod .. " + ALT + Page_Up",  hl.dsp.window.move({ workspace = "-1" }), "Workspaces › Move window previous")
b(mod .. " + O",              M.empty_workspace,                        "Workspaces › Jump to empty workspace")

-- ── Scratchpads ─────────────────────────────────────────────
b(mod .. " + S",              hl.dsp.workspace.toggle_special("magic"),                 "Scratchpads › Magic workspace")
b(mod .. " + ALT + S",        hl.dsp.window.move({ workspace = "special:magic" }),     "Scratchpads › Send window to magic")
b("F12",                      M.scratch("dropdown", term .. " --app-id maxi.dropdown", "^maxi%.dropdown$"), "Scratchpads › Drop-down terminal")
b(mod .. " + A",              M.scratch("dropdown", term .. " --app-id maxi.dropdown", "^maxi%.dropdown$"), "Scratchpads › Drop-down terminal")
b("CTRL + SHIFT + Escape",    M.scratch("sysmon", term .. " --app-id maxi.sysmon -e btop", "^maxi%.sysmon$"), "Scratchpads › System monitor (btop)")
b(mod .. " + M",              M.scratch("music", "spotify", "^[Ss]potify$"),           "Scratchpads › Music (Spotify)")
b(mod .. " + ALT + D",        M.scratch("comms", "discord", "^discord$"),              "Scratchpads › Discord")
b(mod .. " + ALT + Q",        M.scratch("calc", term .. " --app-id maxi.calc -e qalc", "^maxi%.calc$"), "Scratchpads › Calculator (qalc)")

-- ── Modes & effects ─────────────────────────────────────────
b(mod .. " + F2",             M.toggle_game,         "Modes › Game mode")
b(mod .. " + F3",             global("caffeine"),    "Modes › Caffeine (no idle/lock)")
b(mod .. " + F4",             M.cycle_shader,        "Modes › Cycle screen effect")
b(mod .. " + F5",             M.toggle_nightlight,   "Modes › Night light")
b(mod .. " + F6",             M.toggle_zen,          "Modes › Zen mode")
b(mod .. " + F7",             M.toggle_opacity,      "Modes › Toggle transparency")
b(mod .. " + F8",             M.toggle_spin,         "Modes › Toggle spinning borders")
b(mod .. " + F9",             global("reactive"),    "Modes › Audio-reactive desktop")
b(mod .. " + F10",            global("clock"),       "Modes › Desktop clock digital ⇄ analog")
b(mod .. " + F11",            global("stage"),       "Shell › Music Stage (full-screen now playing)")
b(mod .. " + F12",            global("widgets"),     "Shell › Edit desktop widgets")
b(mod .. " + ALT + L",        M.cycle_layout,        "Modes › Cycle layout (dwindle/master/scroll)")
b(mod .. " + CTRL + G",       M.cycle_gaps(1),       "Modes › More gaps")
b(mod .. " + CTRL + SHIFT + G", M.cycle_gaps(-1),    "Modes › Fewer gaps")

-- ── Zoom ────────────────────────────────────────────────────
b(mod .. " + CTRL + Equal",       M.zoom(1.3),  "Zoom › Zoom in", R)
b(mod .. " + CTRL + Minus",       M.zoom(1 / 1.3), "Zoom › Zoom out", R)
b(mod .. " + CTRL + 0",           M.zoom(0),    "Zoom › Reset zoom")
b(mod .. " + CTRL + mouse_down",  M.zoom(1.15), "Zoom › Zoom in (scroll)")
b(mod .. " + CTRL + mouse_up",    M.zoom(1 / 1.15), "Zoom › Zoom out (scroll)")

-- ── Capture ─────────────────────────────────────────────────
b("Print",                    exec(S .. "screenshot.sh full"),   "Capture › Screenshot (full)", L)
b(mod .. " + SHIFT + S",      exec(S .. "screenshot.sh freeze"), "Capture › Screenshot region (frozen)")
b(mod .. " + SHIFT + ALT + S", exec(S .. "screenshot.sh region"), "Capture › Screenshot region (live)")
b(mod .. " + Print",          exec(S .. "screenshot.sh window"), "Capture › Screenshot window")
b(mod .. " + SHIFT + A",      exec(S .. "screenshot.sh edit"),   "Capture › Screenshot + annotate")
b(mod .. " + SHIFT + T",      exec(S .. "screenshot.sh ocr"),    "Capture › OCR region → clipboard")
b(mod .. " + SHIFT + C",      exec(S .. "colorpick.sh"),         "Capture › Colour picker (swatch + HEX/RGB/HSL)")
b("CTRL + ALT + R",           exec(S .. "record.sh"),            "Capture › Record screen + desktop audio (toggle)")
b(mod .. " + ALT + R",        exec(S .. "record.sh region"),     "Capture › Record region + desktop audio (toggle)")
b(mod .. " + SHIFT + ALT + R", exec(S .. "record.sh mic"),       "Capture › Record screen + microphone (toggle)")
b("CTRL + SHIFT + ALT + R",   exec(S .. "record.sh silent"),     "Capture › Record screen, no audio (toggle)")

-- ── Clipboard & text ────────────────────────────────────────
b(mod .. " + V",              exec(S .. "clipboard.sh"),         "Clipboard › History")
b(mod .. " + ALT + V",        exec(S .. "clipboard.sh delete"),  "Clipboard › Delete entry")
b(mod .. " + CTRL + ALT + V", exec(S .. "clipboard.sh wipe"),    "Clipboard › Wipe history")
b(mod .. " + Semicolon",      exec(S .. "emoji.sh"),             "Clipboard › Emoji picker")

-- ── Media & audio ───────────────────────────────────────────
b("XF86AudioRaiseVolume",     exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), "Audio › Volume up", LR)
b("XF86AudioLowerVolume",     exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        "Audio › Volume down", LR)
b(mod .. " + CTRL + Up",      exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), "Audio › Volume up", LR)
b(mod .. " + CTRL + Down",    exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        "Audio › Volume down", LR)
b("XF86AudioMute",            exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        "Audio › Mute", L)
b(mod .. " + SHIFT + M",      exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        "Audio › Mute", L)
b("XF86AudioMicMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      "Audio › Mute microphone", L)
b(mod .. " + ALT + M",        exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      "Audio › Mute microphone", L)
b("XF86AudioPlay",            exec("playerctl play-pause"),                              "Media › Play / pause", L)
b("XF86AudioPause",           exec("playerctl play-pause"),                              "Media › Play / pause", L)
b("XF86AudioNext",            exec("playerctl next"),                                    "Media › Next track", L)
b("XF86AudioPrev",            exec("playerctl previous"),                                "Media › Previous track", L)
b("CTRL + SUPER + Space",     exec("playerctl play-pause"),                              "Media › Play / pause", L)
b("CTRL + SUPER + Period",    exec("playerctl next"),                                    "Media › Next track", L)
b("CTRL + SUPER + Comma",     exec("playerctl previous"),                                "Media › Previous track", L)
b("CTRL + SUPER + Backspace", exec("playerctl stop"),                                    "Media › Stop", L)
b("XF86MonBrightnessUp",      exec("brightnessctl -e4 -n2 set 5%+"),                     "Display › Brightness up", LR)
b("XF86MonBrightnessDown",    exec("brightnessctl -e4 -n2 set 5%-"),                     "Display › Brightness down", LR)

-- ── Session ─────────────────────────────────────────────────
b(mod .. " + L",              exec("pidof hyprlock || hyprlock -c " .. MAXI.dir .. "/hyprlock.conf"), "Session › Lock screen")
b(mod .. " + SHIFT + L",      exec("systemctl suspend"),       "Session › Suspend", L)
b(mod .. " + CTRL + ALT + Delete", exec("hyprctl dispatch 'hl.dsp.exit()'"), "Session › Log out (no confirm)")
