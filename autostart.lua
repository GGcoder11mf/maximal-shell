-- Only fires when Hyprland boots straight into this rice.
-- When switching live, `rice maximal` runs start.sh itself.
hl.on("hyprland.start", function()
    hl.exec_cmd(MAXI.scripts .. "start.sh")
end)

-- Toast when a fullscreen window appears (and a hint for game mode)
hl.on("window.fullscreen", function(win)
    if win and win.fullscreen == 2 and win.class and win.class:match("^steam_app_") and not MAXI.modes.game then
        MAXI.modes.toast("Game detected", "SUPER + F2 for game mode", "sports_esports")
    end
end)
