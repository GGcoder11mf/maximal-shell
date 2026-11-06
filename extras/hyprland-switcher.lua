-- Paste at the TOP of ~/.config/hypr/hyprland.lua (install.sh does this for you).
-- ── Rice switcher ──────────────────────────────────────────────
-- Which rice to load:
--   1. $XDG_RUNTIME_DIR/hypr-rice  — this session's choice (`rice <name>`, wiped at logout)
--   2. ~/.config/hypr/rices/default — the default at login (`rice default <name>`)
--   "caelestia" (or nothing) = the original Caelestia config below.
do
    local function read(path)
        local f = io.open(path)
        if not f then return nil end
        local v = (f:read("*l") or ""):gsub("%s", "")
        f:close()
        return v ~= "" and v or nil
    end
    local home = os.getenv("HOME")
    local rice = read((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-rice")
              or read(home .. "/.config/hypr/rices/default")
    if rice and rice ~= "caelestia" and io.open(home .. "/.config/hypr/rices/" .. rice .. "/init.lua") then
        require("rices." .. rice .. ".init")
        return
    end
end

