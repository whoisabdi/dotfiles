-- ~/.config/hypr/autostart.lua

hl.on("hyprland.start", function ()
  hl.exec_cmd("uwsm app -- env QS_NO_RELOAD_POPUP=1 QML_DISABLE_DISK_CACHE=1 quickshell")
  hl.exec_cmd("uwsm app -- udiskie")
  hl.exec_cmd("uwsm app -- hypridle")
  hl.exec_cmd("uwsm app -- awww-daemon --format xrgb")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
  hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
end)
