-- ~/.config/hypr/input.lua

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0.5,
        repeat_rate = 30,
        repeat_delay = 250,
        scroll_factor = 0.5,

        touchpad = {
            scroll_factor = 0.5,
        }
    },

    cursor = {
        no_warps = true,
        warp_on_change_workspace = 0,
    },

    ecosystem = {
        no_update_news = true,
    }
})
