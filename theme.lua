-- Colour-dependent settings. Re-run live by scripts/wallpaper.sh via
--   hyprctl eval "dofile('<rice>/theme.lua')"
local R = os.getenv("HOME") .. "/.config/hypr/rices/maximal"

local ok, c = pcall(dofile, R .. "/generated/colors.lua")
if not ok or type(c) ~= "table" then
    c = {
        primary = "a7c8ff", secondary = "bdc7dc", tertiary = "dbbce1", primaryContainer = "284777",
        surface = "111318", surfaceContainer = "1d2024", outline = "8e9099", outlineVariant = "44474e",
        error = "ffb4ab", magenta = "f0b0ff", cyan = "80f0e8",
    }
end

local function rgba(hex, a) return "rgba(" .. hex .. a .. ")" end

MAXI_COLORS = c

hl.config({
    general = {
        col = {
            -- 5-stop gradient; the "borderangle" loop animation spins it around every window
            active_border = {
                colors = { rgba(c.primary, "ff"), rgba(c.tertiary, "ff"), rgba(c.magenta, "ff"),
                           rgba(c.cyan, "ff"), rgba(c.primary, "ff") },
                angle = 45,
            },
            inactive_border = { colors = { rgba(c.outlineVariant, "aa"), rgba(c.surfaceContainer, "aa") }, angle = 45 },
            nogroup_border        = rgba(c.outlineVariant, "aa"),
            nogroup_border_active = rgba(c.error, "ff"),
        },
    },

    decoration = {
        shadow = {
            color          = rgba(c.primary, "55"),
            color_inactive = rgba("000000", "66"),
        },
        glow = {
            color          = rgba(c.primary, "4d"),
            color_inactive = rgba(c.primary, "00"),
        },
    },

    group = {
        col = {
            border_active          = { colors = { rgba(c.tertiary, "ff"), rgba(c.magenta, "ff") }, angle = 45 },
            border_inactive        = rgba(c.outlineVariant, "aa"),
            border_locked_active   = rgba(c.error, "ff"),
            border_locked_inactive = rgba(c.error, "77"),
        },
        groupbar = {
            col = {
                active          = rgba(c.primaryContainer, "ee"),
                inactive        = rgba(c.surfaceContainer, "cc"),
                locked_active   = rgba(c.error, "ee"),
                locked_inactive = rgba(c.error, "77"),
            },
        },
    },

    misc = {
        background_color = "rgb(" .. c.surface .. ")",
    },
})
