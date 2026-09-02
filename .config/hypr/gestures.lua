-- ~/.config/hypr/gestures.lua

-- 3 Fingers Horizontal: Switch between standard workspaces
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- 3 Fingers Up: Toggle True Fullscreen (Push to fill screen)
hl.gesture({
    fingers = 3,
    direction = "up",
    action = "fullscreen"
})

-- 3 Fingers Down: Toggle True Fullscreen (Pull to un-fullscreen)
hl.gesture({
    fingers = 3,
    direction = "down",
    action = "fullscreen"
})

-- 4 Fingers Down: Toggle your magic special workspace (Pull down to open)
hl.gesture({
    fingers = 4,
    direction = "down",
    action = "special",
    workspace_name = "magic"
})

-- 4 Fingers Up: Toggle your magic special workspace (Push up to close)
hl.gesture({
    fingers = 4,
    direction = "up",
    action = "special",
    workspace_name = "magic"
})
