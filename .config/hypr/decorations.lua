-- ~/.config/hypr/decorations.lua

local colors = require("colors")

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 2,
        border_size = 2,
        layout = "dwindle",
        allow_tearing = false,
        resize_on_border = false,

        col = {
            active_border = { colors = { colors.primary, colors.secondary }, angle = 45 },
            inactive_border = colors.outline,
        }
    },

    decoration = {
        rounding = 10,
        rounding_power = 3.0, -- Bumped up for true, continuous-curve squircles
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        -- Dimming rules
        dim_inactive = true,
        dim_strength = 0.15, -- Just enough to make the active window pop
        dim_special = 0.4,   -- Dims the background behind your magic workspace

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = colors.shadow,
        },

        blur = {
            enabled = true,
            size = 8,
            passes = 1,
            vibrancy = 0.5,
            xray = true,
            new_optimizations = true,
            popups = true, -- Forces context menus and tooltips to blur
        }
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        enable_swallow = true,
        swallow_regex = "(foot|kitty|alacritty|Alacritty|ghostty|Ghostty|org.wezfurlong.wezterm)",
    }
})
