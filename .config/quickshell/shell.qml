//@ pragma UseQApplication
import Quickshell
import QtQuick
import "globals"
import "ui"
import "bar"
import "launcher"
import "powermenu"
import "osd"
import "notifications"
import "quicksettings"
import "settings"

Scope {
    Item {
        id: globalState
        property var wallpaperCache: []
        property string activeWallpaper: ""
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
            }
        }
    }

    Launcher { id: globalLauncher }
    Powermenu { id: globalPowermenu }
    Osd { id: globalOsd }
    Notifications { id: globalNotifications }
    MediaCenter { id: globalMediaCenter }
    QsPanel { id: globalQsPanel }
    SettingsApp { id: globalSettingsApp }
    WifiPicker { id: globalWifiPicker }
    BluetoothPicker { id: globalBluetoothPicker }
    BatteryDaemon { id: globalBatteryDaemon }
    WallpaperManager { id: globalWallpaperManager }
    BrightnessDaemon { id: globalBrightnessDaemon }
    NetworkDaemon { id: globalNetworkDaemon }
}
