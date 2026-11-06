-- Geometry, effects and EVERY animation. Colours live in theme.lua.
-- modes.lua re-runs this file to restore the look after game/zen mode.

hl.config({
    general = {
        layout           = "dwindle",
        gaps_in          = 6,
        gaps_out         = 14,
        gaps_workspaces  = 60,
        border_size      = 3,
        resize_on_border = true,
        extend_border_grab_area = 18,
        hover_icon_on_border    = true,
        allow_tearing    = true,
    },

    decoration = {
        rounding         = 18,
        rounding_power   = 3.2,          -- squircle corners
        active_opacity   = 0.97,
        inactive_opacity = 0.86,
        fullscreen_opacity = 1.0,
        dim_inactive     = true,
        dim_strength     = 0.08,
        dim_special      = 0.35,
        dim_around       = 0.45,

        blur = {
            enabled            = true,
            size               = 9,
            passes             = 3,
            noise              = 0.03,
            contrast           = 1.05,
            brightness         = 0.9,
            vibrancy           = 0.4,
            vibrancy_darkness  = 0.3,
            popups             = true,
            input_methods      = true,
            special            = true,
            ignore_opacity     = true,
            new_optimizations  = true,
            xray               = false,
        },

        shadow = {
            enabled      = true,
            range        = 28,
            render_power = 3,
            offset       = { 0, 6 },
            scale        = 1.0,
        },

        glow = {                     -- subtle: borders shouldn't out-bloom the shell
            enabled      = true,
            range        = 10,
            render_power = 3,
        },
    },

    dwindle = { preserve_split = true, smart_resizing = true, force_split = 2 },
    master  = { new_status = "master", mfact = 0.55, orientation = "left" },
    scrolling = {
        fullscreen_on_one_column = true,
        column_width             = 0.55,
        focus_fit_method         = 1,
        follow_focus             = true,
        explicit_column_widths   = "0.33, 0.5, 0.66, 1.0",
    },

    group = {
        groupbar = {
            enabled        = true,
            font_family    = "Rubik",
            font_size      = 12,
            height         = 22,
            rounding       = 10,
            gradients      = true,
            gradient_rounding = 10,
            indicator_height = 0,
            keep_upper_gap = false,
        },
    },

    misc = {
        disable_hyprland_logo     = true,
        disable_splash_rendering  = true,
        force_default_wallpaper   = 0,
        focus_on_activate         = true,
        animate_manual_resizes    = true,
        animate_mouse_windowdragging = true,
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        middle_click_paste        = false,
        mouse_move_enables_dpms   = true,
        key_press_enables_dpms    = true,
        vrr                       = 0,
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        scroll_event_delay       = 0,
    },

    cursor = {
        hide_on_key_press = false,
        inactive_timeout  = 0,
        zoom_rigid        = false,
    },

    animations = {
        enabled                = true,
        workspace_wraparound   = false,
    },
})

-- ── Curves ──────────────────────────────────────────────────
hl.curve("linear",     { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("overshot",   { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.08 } } })
hl.curve("snap",       { type = "bezier", points = { { 0.2, 1 }, { 0.3, 1 } } })
hl.curve("decel",      { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("accel",      { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("smooth",     { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } })
hl.curve("bouncy",     { type = "spring", mass = 1, stiffness = 210, dampening = 17 })
hl.curve("jelly",      { type = "spring", mass = 1, stiffness = 320, dampening = 22 })
hl.curve("floaty",     { type = "spring", mass = 1.2, stiffness = 140, dampening = 18 })

-- ── Animations ──────────────────────────────────────────────
local A = function(leaf, speed, curve, style)
    local spec = { leaf = leaf, enabled = true, speed = speed }
    if curve == "bouncy" or curve == "jelly" or curve == "floaty" then spec.spring = curve else spec.bezier = curve end
    if style then spec.style = style end
    hl.animation(spec)
end

A("global",        8,    "smooth")
A("windows",       5,    "bouncy")
A("windowsIn",     5,    "bouncy",   "popin 60%")
A("windowsOut",    3.2,  "accel",    "popin 70%")
A("windowsMove",   5,    "jelly")
A("fade",          4,    "smooth")
A("fadeIn",        3.5,  "decel")
A("fadeOut",       3,    "accel")
A("fadeSwitch",    5,    "smooth")
A("fadeShadow",    5,    "smooth")
A("fadeDim",       5,    "smooth")
A("fadeLayersIn",  3,    "decel")
A("fadeLayersOut", 2.5,  "accel")
A("border",        6,    "smooth")
A("borderangle",   90,   "linear",   "loop")      -- the spinning rainbow border
A("layers",        4,    "floaty")
A("layersIn",      4,    "floaty",   "popin 85%")
A("layersOut",     3,    "accel",    "fade")
A("workspaces",    5,    "jelly",    "slidefade 18%")
A("workspacesIn",  5,    "jelly",    "slidefade 18%")
A("workspacesOut", 5,    "jelly",    "slidefade 18%")
A("specialWorkspace",    5, "floaty", "slidefadevert -40%")
A("specialWorkspaceIn",  5, "floaty", "slidefadevert -40%")
A("specialWorkspaceOut", 4, "accel",  "slidefadevert -40%")
A("zoomFactor",    6,    "jelly")
