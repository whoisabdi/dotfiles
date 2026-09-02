pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property string home: Quickshell.env("HOME")
    readonly property string config: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    readonly property string cache: Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")

    readonly property string qsRoot: config + "/quickshell"
    readonly property string wallCache: cache + "/wallpaper_engine"
}
