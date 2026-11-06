-- ============================================================
--  ███╗   ███╗ █████╗ ██╗  ██╗██╗███╗   ███╗ █████╗ ██╗
--  ████╗ ████║██╔══██╗╚██╗██╔╝██║████╗ ████║██╔══██╗██║
--  ██╔████╔██║███████║ ╚███╔╝ ██║██╔████╔██║███████║██║
--  ██║╚██╔╝██║██╔══██║ ██╔██╗ ██║██║╚██╔╝██║██╔══██║██║
--  ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗██║██║ ╚═╝ ██║██║  ██║███████╗
--  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝
--  Entry point. Loaded by ~/.config/hypr/hyprland.lua when
--  the rice flag says "maximal" (see `rice` in ~/.local/bin).
-- ============================================================

local home = os.getenv("HOME")
MAXI = {
    dir   = home .. "/.config/hypr/rices/maximal",
    shell = home .. "/.config/hypr/rices/maximal/shell",
}
MAXI.scripts = MAXI.dir .. "/scripts/"
MAXI.qs      = "qs -p " .. MAXI.shell

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

require("rices.maximal.env")
require("rices.maximal.look")
dofile(MAXI.dir .. "/theme.lua") -- colours (re-runnable)
require("rices.maximal.input")
require("rices.maximal.rules")
require("rices.maximal.modes")
require("rices.maximal.keybinds")
require("rices.maximal.submaps")
require("rices.maximal.autostart")
