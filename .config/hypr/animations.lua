-- Core Curves
hl.curve("cupertinoSpring", {type = "spring", mass = 1.0, stiffness = 130.45, dampening = 22.84})
hl.curve("cupertinoEase", {type = "bezier", points = {{0.25, 0.1}, {0.25, 1.0}}})
hl.curve("cupertinoAlpha", {type = "bezier", points = {{0.0, 0.0}, {1.0, 1.0}}})

-- Opacity Transitions
hl.animation({leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeDim", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadePopups", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "fade", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})

-- Spatial Dynamics
hl.animation({leaf = "windows", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "popin 90%"})
hl.animation({leaf = "windowsIn", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "popin 90%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = 3.0, bezier = "cupertinoEase", style = "popin 90%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "slide"})

-- Workspaces
hl.animation({leaf = "workspaces", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "slidefade 20%"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "slidefade 20%"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "slidefade 20%"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "slidefade 20%"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "slidefade 20%"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = 5.5, spring = "cupertinoSpring", style = "slidefade 20%"})

-- UI Elements
hl.animation({leaf = "border", enabled = true, speed = 2.5, bezier = "cupertinoAlpha"})
hl.animation({leaf = "borderangle", enabled = false})
hl.animation({leaf = "zoomFactor", enabled = true, speed = 5.5, bezier = "cupertinoEase"})
hl.animation({leaf = "monitorAdded", enabled = true, speed = 5.5, spring = "cupertinoSpring"})
