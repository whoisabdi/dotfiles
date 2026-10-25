-- ~/.config/hypr/windowrules.lua

-- =============================================================================
-- GLOBAL WINDOW FIXES
-- =============================================================================
-- Ignore maximize requests from applications (prevents misbehaved full-screen glitches)
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize"
})

-- Fix empty XWayland drag surfaces stealing focus
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Monocle / maximized workspace rule
hl.workspace_rule({
    workspace = "f[1]",
    gaps_out = 0,
    border_size = 0,
    no_rounding = true,
})

-- =============================================================================
-- TAG ASSIGNMENTS
-- =============================================================================
-- Web Browsers
hl.window_rule({ match = { class = "^(google-chrome(-stable)?)$" }, tag = "+browser" })

-- Multimedia: Video Players (Celluloid)
hl.window_rule({ match = { class = "^(io\\.github\\.celluloid_player\\.Celluloid|celluloid)$" }, tag = "+multimedia_video" })

-- Multimedia: Audio Players (Spotify)
hl.window_rule({ match = { class = "^([Ss]potify|spotify)$" }, tag = "+multimedia_audio" })
hl.window_rule({ match = { initial_title = "^(Spotify Free|Spotify Premium)$" }, tag = "+multimedia_audio" })

-- Document & Image Viewers
hl.window_rule({ match = { class = "^(feh|evince|org\\.gnome\\.Evince|satty|com\\.gabm\\.satty)$" }, tag = "+viewer" })

-- Archive Managers (Ark)
hl.window_rule({ match = { class = "^(org\\.kde\\.ark|ark)$" }, tag = "+archive" })

-- File Managers (Nautilus)
hl.window_rule({ match = { class = "^(org\\.gnome\\.Nautilus|nautilus)$" }, tag = "+file-manager" })

-- Development & Code Editors
hl.window_rule({ match = { class = "^(codium-oss|[Cc]odium|[Vv]scodium|codium-url-handler)$" }, tag = "+projects" })

-- Settings & Control Centers
hl.window_rule({ match = { class = "^(qt5ct|qt6ct|nwg-look|nm-applet|nm-connection-editor|hyprpolkitagent|pavucontrol|org\\.pulseaudio\\.pavucontrol|auto-cpufreq|auto-cpufreq-gtk|app\\.py)$" }, tag = "+settings" })
hl.window_rule({ match = { title = ".*auto-cpufreq.*" }, tag = "+settings" })

-- Portals & Authentication Agents
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\.gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\.hyprland|.*polkit.*)$" }, tag = "+dialog" })

-- =============================================================================
-- RULES BY TAG
-- =============================================================================
-- Web Browsers
hl.window_rule({ match = { tag = "browser" }, idle_inhibit = "fullscreen", opacity = "0.9 0.9" })

-- Video Players (Floating with 100% solid opacity for video fidelity)
hl.window_rule({
    match = { tag = "multimedia_video" },
    float = true,
    center = true,
    idle_inhibit = "focus",
    size = {"(monitor_w * 0.7)", "(monitor_h * 0.7)"},
    opacity = "1.0 1.0"
})

-- Celluloid Preferences
hl.window_rule({
    match = { class = "^(io\\.github\\.celluloid_player\\.Celluloid|celluloid)$"},
    float = true,
    center = true,
    size = {"(monitor_w * 0.7)", "(monitor_h * 0.7)"}
})

-- Spotify & Audio (Floating with expanded width/height for full UI)
hl.window_rule({
    match = { tag = "multimedia_audio" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.78)", "(monitor_h * 0.82)"},
    opacity = "0.9 0.9"
})

-- Image & PDF Viewers (Floating with 100% solid opacity for image accuracy)
hl.window_rule({
    match = { tag = "viewer" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.75)", "(monitor_h * 0.75)"},
    opacity = "1.0 1.0"
})

-- Archive Managers (Floating)
hl.window_rule({
    match = { tag = "archive" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.55)", "(monitor_h * 0.6)"},
    opacity = "0.95 0.95"
})

-- File Managers (Nautilus)
hl.window_rule({ match = { tag = "file-manager" }, opacity = "0.8 0.8" })

-- Development & Code Editors (Floating)
hl.window_rule({
    match = { tag = "projects" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.85)", "(monitor_h * 0.85)"},
    opacity = "0.85 0.85"
})

-- Settings Windows (Floating & Centered)
hl.window_rule({
    match = { tag = "settings" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.5)", "(monitor_h * 0.65)"},
    opacity = "0.95 0.95"
})

-- =============================================================================
-- EXCEPTIONS & MODAL OVERRIDES
-- =============================================================================
-- Authentication & Polkit Agents
hl.window_rule({
    match = { class = "^(.*polkit.*)$" },
    float = true,
    center = true,
    stay_focused = true,
    pin = true,
    opacity = "1.0 1.0"
})

-- Portal File Choosers
hl.window_rule({
    match = { class = "^(xdg-desktop-portal-gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\.gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\.hyprland)$" },
    float = true,
    center = true,
    stay_focused = true,
    size = {"(monitor_w * 0.6)", "(monitor_h * 0.7)"},
    opacity = "0.95 0.95"
})

-- Modal & Standard Action Dialogs
hl.window_rule({
    match = { title = "^(Open|Open File|Open Folder|Save|Save As|Save File|Select.*|Choose.*|Confirm.*|Authentication.*|File Operation Progress|Properties)$" },
    float = true,
    center = true,
    stay_focused = true,
    opacity = "0.95 0.95"
})

-- Satty Screenshot Editor
hl.window_rule({
    match = { class = "^(satty|com\\.gabm\\.satty)$" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.85)", "(monitor_h * 0.85)"},
    opacity = "1.0 1.0"
})

-- auto-cpufreq Optimizer Popup
hl.window_rule({
    match = { class = "^(auto-cpufreq|auto-cpufreq-gtk|app\\.py)$" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.55)", "(monitor_h * 0.65)"},
    opacity = "0.95 0.95"
})
hl.window_rule({
    match = { title = ".*auto-cpufreq.*" },
    float = true,
    center = true,
    size = {"(monitor_w * 0.55)", "(monitor_h * 0.65)"},
    opacity = "0.95 0.95"
})

-- Picture-in-Picture (PiP)
hl.window_rule({
    name = "picture_in_picture",
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    keep_aspect_ratio = true,
    move = {"(monitor_w * 0.73)", "(monitor_h * 0.72)"},
    size = {"(monitor_w * 0.25)", "(monitor_h * 0.25)"},
    pin = true,
    idle_inhibit = "always",
    opacity = "1.0 1.0"
})

-- =============================================================================
-- LAYER RULES
-- =============================================================================
hl.layer_rule({ name = "bar-blur", match = { namespace = "bar" }, blur = true, blur_popups = true })
hl.layer_rule({ name = "launcher-blur", match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "powermenu-blur", match = { namespace = "powermenu" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "qspanel-blur", match = { namespace = "qspanel" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "osd-blur", match = { namespace = "osd" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "wifipicker-blur", match = { namespace = "wifipicker" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "btpicker-blur", match = { namespace = "btpicker" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "settingsapp-blur", match = { namespace = "settingsapp" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "mediacenter-blur", match = { namespace = "mediacenter" }, blur = true, ignore_alpha = 0.41 })
hl.layer_rule({ name = "notifications-blur", match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.41, no_anim = true })



