import QtQuick
import Quickshell.Io

Item {
    id: root

    property int brightness: 100
    property bool isReady: false
    property bool hasDdcutil: false
    property var ddcBuses: []

    Process {
        id: checkDdcProc
        command: ["which", "ddcutil"]
        onExited: (exitCode) => {
            root.hasDdcutil = (exitCode === 0);
            if (root.hasDdcutil) detectDdcProc.running = true;
        }
    }

    Process {
        id: detectDdcProc
        command: ["sh", "-c", "ddcutil detect --brief 2>/dev/null | grep -E '^Display' | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n").filter(l => l.length > 0);
                root.ddcBuses = lines;
            }
        }
    }

    Process {
        id: setDdcProc
        property int targetPct: 50
        command: ["sh", "-c", "for b in " + root.ddcBuses.join(" ") + "; do ddcutil setvcp 10 " + targetPct + " --display $b 2>/dev/null & done"]
    }

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
        if (root.hasDdcutil && root.ddcBuses.length > 0) {
            setDdcProc.targetPct = val
            setDdcProc.running = true
        }
    }

    function adjust(delta) {
        setBrightness(root.brightness + delta)
    }

    IpcHandler {
        target: "brightness"

        function increment(delta: int): void {
            root.adjust(delta || 5);
        }

        function decrement(delta: int): void {
            root.adjust(-(delta || 5));
        }

        function set(val: int): void {
            root.setBrightness(val);
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: readProc.running = true
    }

    Component.onCompleted: {
        readProc.running = true;
        checkDdcProc.running = true;
    }
}
