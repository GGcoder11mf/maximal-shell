-- Modal keymaps. The shell listens for Hyprland's "submap" event and shows a
-- hint card with that submap's binds while it's active.
local mod  = "SUPER"
local exec = hl.dsp.exec_cmd
local R    = { repeating = true }
local term = "foot -c " .. MAXI.dir .. "/foot.ini"

local function b(key, action, desc, flags)
    flags = flags or {}
    flags.description = desc
    hl.bind(key, action, flags)
end
local function exit_keys()
    b("Escape", hl.dsp.submap("reset"), "Exit")
    b("Return", hl.dsp.submap("reset"), "Exit")
end
-- run an action, then leave the submap
local function once(action)
    return function()
        if type(action) == "function" then action() else hl.dispatch(action) end
        hl.dispatch(hl.dsp.submap("reset"))
    end
end

-- ── RESIZE  (SUPER + R) ─────────────────────────────────────
b(mod .. " + R", hl.dsp.submap("resize"), "Modes › Resize mode (arrows / hjkl)")
hl.define_submap("resize", function()
    for _, k in ipairs({ { "left", "h", -40, 0 }, { "right", "l", 40, 0 }, { "up", "k", 0, -40 }, { "down", "j", 0, 40 } }) do
        b(k[1], hl.dsp.window.resize({ x = k[3], y = k[4], relative = true }), "Resize " .. k[1], R)
        b(k[2], hl.dsp.window.resize({ x = k[3], y = k[4], relative = true }), "Resize " .. k[1], R)
        b("SHIFT + " .. k[1], hl.dsp.window.resize({ x = k[3] * 4, y = k[4] * 4, relative = true }), "Resize " .. k[1] .. " ×4", R)
    end
    b("c", hl.dsp.window.center(), "Centre")
    b("f", hl.dsp.window.float({ action = "toggle" }), "Toggle float")
    exit_keys()
end)

-- ── MOVE  (SUPER + SHIFT + R) ───────────────────────────────
b(mod .. " + SHIFT + R", hl.dsp.submap("move"), "Modes › Move mode (arrows / hjkl)")
hl.define_submap("move", function()
    for _, k in ipairs({ { "left", "h", "l" }, { "right", "l", "r" }, { "up", "k", "u" }, { "down", "j", "d" } }) do
        b(k[1], hl.dsp.window.move({ direction = k[1] }), "Move " .. k[1], R)
        b(k[2], hl.dsp.window.move({ direction = k[1] }), "Move " .. k[1], R)
        b("SHIFT + " .. k[1], hl.dsp.window.swap({ direction = k[1] }), "Swap " .. k[1])
    end
    for i = 1, 9 do b(tostring(i), once(hl.dsp.window.move({ workspace = i })), "Send to workspace " .. i) end
    exit_keys()
end)

-- ── LAUNCH leader  (SUPER + Y, then a letter) ───────────────
b(mod .. " + Y", hl.dsp.submap("launch"), "Modes › Launch leader (then a letter)")
hl.define_submap("launch", function()
    local apps = {
        { "t", term,                  "Terminal" },
        { "w", "zen-browser",         "Zen browser" },
        { "f", "firefox",             "Firefox" },
        { "e", "thunar",              "Files" },
        { "c", "code",                "VS Code" },
        { "n", term .. " -e nvim",    "Neovim" },
        { "s", "spotify",             "Spotify" },
        { "d", "discord",             "Discord" },
        { "m", "thunderbird",         "Thunderbird" },
        { "o", "obs",                 "OBS" },
        { "b", term .. " -e btop",    "btop" },
        { "v", "pwvucontrol",         "Volume mixer" },
        { "q", term .. " -e qalc",    "Calculator" },
        { "y", term .. " -e fastfetch --pipe false; read -n1", "Fastfetch" },
        { "x", term .. " -e cmatrix", "The Matrix" },
    }
    for _, a in ipairs(apps) do b(a[1], once(exec(a[2])), a[3]) end
    exit_keys()
end)

-- ── POWER chord  (SUPER + CTRL + Escape, then a letter) ─────
b(mod .. " + CTRL + Escape", hl.dsp.submap("power"), "Session › Power chord (l/s/r/p/e)")
hl.define_submap("power", function()
    b("l", once(exec("hyprlock -c " .. MAXI.dir .. "/hyprlock.conf")), "Lock")
    b("s", once(exec("systemctl suspend")),  "Suspend")
    b("r", once(exec("systemctl reboot")),   "Reboot")
    b("p", once(exec("systemctl poweroff")), "Power off")
    b("e", once(hl.dsp.exit()),              "Exit Hyprland")
    exit_keys()
end)
