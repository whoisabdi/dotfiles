import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper.sh"

    Process { id: startupWallProc; command: ["bash", scriptPath, "--restore"] }
    Process { id: randomWallProc; command: ["bash", scriptPath] }

    Component.onCompleted: startupWallProc.running = true

    IpcHandler {
        target: "wallpaper"
        function randomize(): void {
            randomWallProc.running = false
            randomWallProc.running = true
        }
    }
}
