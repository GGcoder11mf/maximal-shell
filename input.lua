hl.config({
    input = {
        kb_layout          = "us",
        repeat_delay       = 250,
        repeat_rate        = 35,
        follow_mouse       = 1,
        focus_on_close     = 1,
        numlock_by_default = false,
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            scroll_factor        = 0.3,
            clickfinger_behavior = true,
        },
    },

    gestures = {
        workspace_swipe_distance           = 700,
        workspace_swipe_cancel_ratio       = 0.15,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_create_new         = true,
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",   action = "special", workspace_name = "magic" })
hl.gesture({ fingers = 3, direction = "down", action = function() hl.dispatch(hl.dsp.global("maxi:dashboard")) end })
