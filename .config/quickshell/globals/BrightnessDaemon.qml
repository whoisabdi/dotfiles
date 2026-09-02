import QtQuick
import Quickshell.Io

Item {
    id: root

    property int brightness: 100
    property bool isReady: false

    Process {
        id: readProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(",")
                if (parts.length >= 4) {
                    let pct = parseInt(parts[3].replace("%", "").trim())
                    if (!isNaN(pct)) {
                        root.brightness = pct
                        root.isReady = true
                    }
                }
            }
        }
    }

    Process {
        id: setProc
        property int targetPct: 50
        command: ["brightnessctl", "set", targetPct + "%"]
        onExited: readProc.running = true
    }

    function setBrightness(pct) {
        let val = Math.max(1, Math.min(100, Math.round(pct)))
        root.brightness = val
        setProc.targetPct = val
        setProc.running = true
    }

    function adjust(delta) {
        setBrightness(root.brightness + delta)
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: readProc.running = true
    }

    Component.onCompleted: readProc.running = true
}
