-- Custom features callable from keybinds: toasts, scratchpads, layout/gap
-- cycling, game & zen modes, zoom, screen shaders, opacity…
local M = {}
MAXI.modes = M

local function q(s) return "'" .. tostring(s):gsub("'", "'\\''") .. "'" end

-- Toast in the Quickshell shell (falls back to Hyprland's notifier)
function M.toast(title, body, icon)
    hl.exec_cmd(MAXI.qs .. " ipc call toast pop " .. q(title) .. " " .. q(body or "") .. " " .. q(icon or "info")
        .. " || hyprctl notify 1 2500 0 " .. q(title .. "  " .. (body or "")))
end

function M.shell(target, fn, ...)
    local args = {}
    for _, a in ipairs({ ... }) do args[#args + 1] = q(a) end
    hl.exec_cmd(MAXI.qs .. " ipc call " .. target .. " " .. fn .. " " .. table.concat(args, " "))
end

-- ── Scratchpads ─────────────────────────────────────────────
local function find_class(pattern)
    for _, w in ipairs(hl.get_windows() or {}) do
        if w.class and w.class:match(pattern) then return w end
    end
end

function M.scratch(name, cmd, class_pattern)
    return function()
        local w = find_class(class_pattern)
        if w and w.workspace and w.workspace.name ~= "special:" .. name then
            hl.dispatch(hl.dsp.window.move({ window = "address:" .. w.address, workspace = "special:" .. name, follow = false }))
        end
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        if not w then hl.exec_cmd(cmd) end
    end
end

-- ── Layouts ─────────────────────────────────────────────────
local layouts = { "dwindle", "master", "scrolling" }
local layout_icons = { dwindle = "view_quilt", master = "view_sidebar", scrolling = "view_column" }

function M.cycle_layout()
    local cur = hl.get_config("general.layout")
    local nxt = layouts[1]
    for i, l in ipairs(layouts) do
        if l == cur then nxt = layouts[i % #layouts + 1] end
    end
    hl.config({ general = { layout = nxt } })
    M.toast("Layout", nxt, layout_icons[nxt])
end

-- ── Gaps ────────────────────────────────────────────────────
local gap_tiers = { { 0, 0, "none" }, { 3, 6, "tight" }, { 6, 14, "default" }, { 14, 34, "airy" }, { 26, 70, "gallery" } }
local gap_i = 3
function M.cycle_gaps(dir)
    return function()
        gap_i = (gap_i - 1 + (dir or 1)) % #gap_tiers + 1
        local t = gap_tiers[gap_i]
        hl.config({ general = { gaps_in = t[1], gaps_out = t[2] } })
        M.toast("Gaps", t[3] .. "  ·  " .. t[1] .. " / " .. t[2] .. " px", "padding")
    end
end

-- ── Restore the full look (after game / zen) ────────────────
local function restore_look()
    local layout = hl.get_config("general.layout")
    dofile(MAXI.dir .. "/look.lua")
    dofile(MAXI.dir .. "/theme.lua")
    hl.config({ general = { layout = layout } })
    gap_i = 3
end

-- ── Game mode: everything off, maximum fps ──────────────────
M.game = false
function M.toggle_game()
    M.game = not M.game
    if M.game then
        if M.zen then M.zen = false end
        hl.config({
            animations = { enabled = false },
            general    = { gaps_in = 0, gaps_out = 0, border_size = 1 },
            decoration = {
                rounding = 0, active_opacity = 1, inactive_opacity = 1, dim_inactive = false,
                blur = { enabled = false }, shadow = { enabled = false }, glow = { enabled = false },
            },
        })
    else
        restore_look()
    end
    M.shell("state", "set", "gameMode", tostring(M.game))
    M.toast("Game mode", M.game and "ON · animations, blur & gaps disabled" or "OFF · eye candy restored", "sports_esports")
end

-- ── Zen mode: no bar, no gaps, no borders ───────────────────
M.zen = false
function M.toggle_zen()
    M.zen = not M.zen
    if M.zen then
        hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { rounding = 0, dim_inactive = false } })
    else
        restore_look()
    end
    M.shell("state", "set", "barHidden", tostring(M.zen))
    M.toast("Zen mode", M.zen and "ON" or "OFF", "self_improvement")
end

-- ── Transparency ────────────────────────────────────────────
M.opaque = false
function M.toggle_opacity()
    M.opaque = not M.opaque
    hl.config({ decoration = { active_opacity = M.opaque and 1 or 0.97, inactive_opacity = M.opaque and 1 or 0.86 } })
    M.toast("Transparency", M.opaque and "OFF · solid windows" or "ON · glass windows", "opacity")
end

-- ── Spinning border on/off ──────────────────────────────────
M.spin = true
function M.toggle_spin()
    M.spin = not M.spin
    hl.animation({ leaf = "borderangle", enabled = M.spin, speed = 90, bezier = "linear", style = "loop" })
    M.toast("Border animation", M.spin and "spinning" or "paused", "rotate_right")
end

-- ── Screen shaders ──────────────────────────────────────────
local shaders = {
    { "",             "off",         "texture" },
    { "nightlight",   "night light", "nightlight" },
    { "vibrance",     "vibrance",    "palette" },
    { "grayscale",    "grayscale",   "filter_b_and_w" },
    { "crt",          "retro CRT",   "tv" },
}
local shader_i = 1
local function apply_shader(i)
    shader_i = i
    local s = shaders[i]
    hl.config({ decoration = { screen_shader = s[1] == "" and "" or (MAXI.dir .. "/shaders/" .. s[1] .. ".glsl") } })
    M.shell("state", "set", "shader", s[1])
    M.toast("Screen effect", s[2], s[3])
end
function M.cycle_shader() apply_shader(shader_i % #shaders + 1) end
function M.toggle_nightlight() apply_shader(shader_i == 2 and 1 or 2) end

-- ── Music sync: the shell calls MAXI.modes.beat(flare, c1, c2, c3, c4, gain) ──
--   c1..c4 = the shell's CURRENT palette -> window borders always match the shell.
--   flare > 0 = a beat: a short, modest glow flare (scaled by intensity), settled 220 ms later.
-- Cheap by design: at most ~4 calls/s, each ONE hl.config (+ one settle).
local reset_timer = nil
local last_c1 = nil
local GLOW_BASE_RANGE, GLOW_BASE_ALPHA = 10, 0x4d
local function glow(range, alpha, hex)
    return { range = math.floor(range), color = "rgba(" .. hex .. string.format("%02x", math.floor(alpha)) .. ")" }
end
local function settle()
    local hex = last_c1 or (MAXI_COLORS or {}).primary or "a7c8ff"
    hl.config({ decoration = { glow = glow(GLOW_BASE_RANGE, GLOW_BASE_ALPHA, hex) } })
end
function M.beat(flare, c1, c2, c3, c4, gain)
    if M.game then return end
    flare = math.max(0, math.min(1, tonumber(flare) or 0))
    gain = math.max(0, math.min(1, tonumber(gain) or 1))
    local spec = {}
    if c1 and c2 and c3 and c4 then
        last_c1 = c1
        local function a(h) return "rgba(" .. h .. "ff)" end
        spec.general = { col = { active_border = { colors = { a(c1), a(c2), a(c3), a(c4), a(c1) }, angle = 45 } } }
    end
    local hex = last_c1 or (MAXI_COLORS or {}).primary or "a7c8ff"
    if flare > 0 then
        local t = flare * gain
        spec.decoration = { glow = glow(GLOW_BASE_RANGE + 10 * t, GLOW_BASE_ALPHA + 0x40 * t, hex) }
        if reset_timer then reset_timer:set_enabled(false) end      -- cancel a pending settle
        reset_timer = hl.timer(settle, { timeout = 220, type = "oneshot" })
    else
        spec.decoration = { glow = glow(GLOW_BASE_RANGE, GLOW_BASE_ALPHA, hex) }
    end
    hl.config(spec)
end

-- ── Zoom ────────────────────────────────────────────────────
function M.zoom(factor)
    return function()
        local z = tonumber(hl.get_config("cursor.zoom_factor")) or 1
        z = factor == 0 and 1 or math.max(1, math.min(z * factor, 8))
        hl.config({ cursor = { zoom_factor = z } })
    end
end

-- ── Window helpers ──────────────────────────────────────────
function M.float_center(w_pct, h_pct)
    return function()
        local win = hl.get_active_window()
        local mon = hl.get_active_monitor()
        if not (win and mon) then return end
        if not win.floating then hl.dispatch(hl.dsp.window.float({ action = "on" })) end
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(mon.width / mon.scale * w_pct), y = math.floor(mon.height / mon.scale * h_pct), relative = false,
        }))
        hl.dispatch(hl.dsp.window.center())
    end
end

-- Send every window on the current workspace to a fresh empty workspace
function M.empty_workspace()
    hl.dispatch(hl.dsp.focus({ workspace = "empty" }))
end

return M
