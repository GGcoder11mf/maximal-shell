-- Window, workspace and layer rules

local function rule(match, props)
    props.match = match
    hl.window_rule(props)
end

-- ── Sanity ───────────────────────────────────────────────────
rule({ class = ".*" }, { suppress_event = "maximize" })
rule({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

-- ── Scratchpads (spawned by modes.lua -> scratch()) ──────────
local scratch = {
    { "^(maxi\\.dropdown)$", "dropdown", "(monitor_w*0.72) (monitor_h*0.55)", "(monitor_w*0.14) (60)" },
    { "^(maxi\\.sysmon)$",   "sysmon",   "(monitor_w*0.8) (monitor_h*0.8)",   nil },
    { "^(maxi\\.calc)$",     "calc",     "(monitor_w*0.4) (monitor_h*0.5)",   nil },
}
for _, s in ipairs(scratch) do
    local p = { float = true, size = s[3], workspace = "special:" .. s[2] .. " silent" }
    if s[4] then p.move = s[4] else p.center = true end
    rule({ class = s[1] }, p)
end
rule({ class = "^([Ss]potify)$" }, { workspace = "special:music silent" })
rule({ class = "^(discord|vesktop)$" }, { workspace = "special:comms silent" })

-- ── Floating utilities ───────────────────────────────────────
for _, cls in ipairs({
    "pwvucontrol", "com.saivert.pwvucontrol", "pavucontrol", "nm-connection-editor", "blueman-manager",
    "org.gnome.Calculator", "qalculate-gtk", "xdg-desktop-portal-gtk", "file-roller", "zenity", "yad",
    "com.gabm.satty", "satty", "nwg-look", "qt6ct", "kvantummanager", "imv", "mpv",
}) do
    rule({ class = "^(" .. cls .. ")$" }, { float = true, center = true, size = "(monitor_w*0.55) (monitor_h*0.65)" })
end

rule({ title = "^(Open File|Save File|Save As|Open Folder|Select a File|Choose Files|File Upload).*" },
    { float = true, center = true, size = "(monitor_w*0.6) (monitor_h*0.7)", dim_around = true })
rule({ class = "^(polkit-gnome-authentication-agent-1)$" }, { float = true, center = true, dim_around = true, pin = true })

-- Picture-in-picture: small, pinned, bottom-right
rule({ title = "^(Picture[- ]in[- ][Pp]icture)$" }, {
    float = true, pin = true, keep_aspect_ratio = true,
    size = "(monitor_w*0.25) (monitor_h*0.25)", move = "(monitor_w*0.74) (monitor_h*0.72)",
})

-- Media/players never get transparency
rule({ class = "^(mpv|vlc|obs|com.obsproject.Studio|zen|firefox|code|Code|code-oss)$" }, { opacity = "1.0 override 0.94 override" })

-- Games: tear-free off, full opacity, idle inhibit
rule({ class = "^(steam_app_.*|gamescope|.*\\.exe)$" }, { immediate = true, opaque = true, idle_inhibit = "always", no_blur = true, no_shadow = true })
rule({ fullscreen = true }, { idle_inhibit = "fullscreen" })

-- ── Workspace rules ──────────────────────────────────────────
-- Single tiled window gets more breathing room
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 26 })
hl.workspace_rule({ workspace = "special:dropdown", gaps_out = 0 })

-- ── Layer rules (Quickshell surfaces animate themselves) ─────
hl.layer_rule({ match = { namespace = "^maxi-(bar|panel|notifs|osd|toast|dock)$" }, blur = true, ignore_alpha = 0.25, no_anim = true })
hl.layer_rule({ match = { namespace = "^maxi-overlay$" }, blur = true, ignore_alpha = 0.01, animation = "fade" })
hl.layer_rule({ match = { namespace = "^maxi-bg$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^maxi-stage$" }, animation = "fade" })   -- opaque: no blur
hl.layer_rule({ match = { namespace = "^launcher$" }, blur = true, ignore_alpha = 0.3, animation = "popin 85%" }) -- fuzzel
hl.layer_rule({ match = { namespace = "^(selection|hyprpicker)$" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.3 })

-- Dolphin & KDE utilities: frosted glass via Hyprland (blur shows the wallpaper through).
-- Colours/fonts/icons come from the rice's qtengine.json + matugen KDE scheme; shape from xdg/darklyrc.
rule({ class = "^(org.kde.dolphin|org.kde.ark|org.kde.kate)$" }, { opacity = "0.88 override 0.8 override" })
