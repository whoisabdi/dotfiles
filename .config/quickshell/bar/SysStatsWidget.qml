import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../globals"
import "../ui"

RowLayout {
    id: root
    spacing: 8

    property int cpuPct: 0
    property string memUsed: "0.0"
    property string memTotal: "0.0"
    property int memPct: 0
    property int cpuTemp: 0
    property int cpuMhz: 0
    property int gpuTemp: 0

    property bool showMemPct: false
    property bool userToggledTemp: false

    // Available space passed dynamically from parent Bar layout
    property real availableSpace: 300

    readonly property real statsPillWidth: statsPill.implicitWidth
    readonly property real tempsPillWidth: tempsPill.implicitWidth

    // Progressive overflow sizing:
    // 1. Ample space: show both pills
    // 2. Moderate space: show stats pill (thermals accessible on CPU click)
    // 3. Very tight space: hide stats to preserve workspaces & taskbar
    readonly property bool showTempsPill: availableSpace >= (statsPillWidth + tempsPillWidth + root.spacing)
    readonly property bool showStatsPill: availableSpace >= statsPillWidth

    readonly property real visiblePillsWidth: (statsPill.visible ? statsPill.implicitWidth : 0)
                                            + (tempsPill.visible ? tempsPill.implicitWidth + (statsPill.visible ? root.spacing : 0) : 0)

    Process {
        id: btopProc
        command: ["kitty", "--class", "btop", "-e", "btop"]
    }

    Process {
        id: autoCpuProc
        command: ["auto-cpufreq-gtk"]
    }

    Process {
        id: statsProc
        command: ["/home/nightwing/.config/quickshell/scripts/sys_stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split("|")
                if (parts.length >= 6) {
                    root.cpuPct = parseInt(parts[0]) || 0
                    root.memUsed = parts[1] || "0.0"
                    root.memTotal = parts[2] || "0.0"
                    root.memPct = parseInt(parts[3]) || 0
                    root.cpuTemp = parseInt(parts[4]) || 0
                    root.cpuMhz = parseInt(parts[5]) || 0
                    root.gpuTemp = parts.length >= 7 ? (parseInt(parts[6]) || root.cpuTemp) : root.cpuTemp
                }
            }
        }
    }

    Component.onCompleted: statsProc.running = true

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: statsProc.running = true
    }

    function getThermoIcon(temp) {
        if (temp >= 85) return "";
        if (temp >= 65) return "";
        if (temp >= 45) return "";
        return "";
    }

    function getMemIcon(pct) {
        if (pct >= 90) return "";
        if (pct >= 60) return "󰓅";
        if (pct >= 30) return "󰾅";
        return "󰾆";
    }

    // Pill 1: Resources (CPU & RAM)
    Pill {
        id: statsPill
        visible: root.showStatsPill
        clickable: true
        paddingHorizontal: 9
        spacing: 8

        onClicked: btopProc.running = true
        onRightClicked: autoCpuProc.running = true

        // CPU Usage (or Temp toggle when tempsPill is hidden due to overflow)
        MouseArea {
            id: cpuItemArea
            implicitWidth: cpuLayout.implicitWidth
            implicitHeight: cpuLayout.implicitHeight
            cursorShape: (!root.showTempsPill) ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    if (!root.showTempsPill) {
                        root.userToggledTemp = !root.userToggledTemp
                    } else {
                        btopProc.running = true
                    }
                } else if (mouse.button === Qt.RightButton) {
                    autoCpuProc.running = true
                }
            }

            RowLayout {
                id: cpuLayout
                spacing: 3

                QsText {
                    text: (!root.showTempsPill && root.userToggledTemp) ? root.getThermoIcon(root.cpuTemp) : "󰍛"
                    font.family: "CaskaydiaCove Nerd Font"
                    font.pixelSize: 12
                    color: {
                        if (!root.showTempsPill && root.userToggledTemp) {
                            if (root.cpuTemp >= 85) return Colors.md3.error;
                            if (root.cpuTemp >= 65) return Colors.md3.tertiary;
                            return Colors.md3.primary;
                        } else {
                            if (root.cpuPct >= 80) return Colors.md3.error;
                            if (root.cpuPct >= 50) return Colors.md3.tertiary;
                            return Colors.md3.primary;
                        }
                    }
                }

                QsText {
                    text: (!root.showTempsPill && root.userToggledTemp) ? (root.cpuTemp + "°C") : (root.cpuPct + "%")
                    font.family: "CaskaydiaCove Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    color: Colors.md3.on_surface
                }
            }
        }

        // Memory Usage
        MouseArea {
            id: memClickArea
            implicitWidth: memLayout.implicitWidth
            implicitHeight: memLayout.implicitHeight
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    root.showMemPct = !root.showMemPct
                } else if (mouse.button === Qt.RightButton) {
                    btopProc.running = true
                }
            }

            RowLayout {
                id: memLayout
                spacing: 3

                QsText {
                    text: root.getMemIcon(root.memPct)
                    font.family: "CaskaydiaCove Nerd Font"
                    font.pixelSize: 12
                    color: {
                        if (root.memPct >= 90) return Colors.md3.error;
                        if (root.memPct >= 60) return Colors.md3.tertiary;
                        return Colors.md3.secondary;
                    }
                }

                QsText {
                    text: root.showMemPct ? (root.memPct + "%") : (root.memUsed + "GB")
                    font.family: "CaskaydiaCove Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    color: Colors.md3.on_surface
                }
            }
        }
    }

    // Pill 2: Thermals (CPU & GPU) - automatically hides on overflow
    Pill {
        id: tempsPill
        visible: root.showTempsPill
        clickable: true
        paddingHorizontal: 9
        spacing: 8

        onClicked: btopProc.running = true
        onRightClicked: autoCpuProc.running = true

        // CPU Thermals
        RowLayout {
            spacing: 3

            QsText {
                text: root.getThermoIcon(root.cpuTemp)
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 12
                color: {
                    if (root.cpuTemp >= 85) return Colors.md3.error;
                    if (root.cpuTemp >= 65) return Colors.md3.tertiary;
                    return Colors.md3.primary;
                }
            }

            QsText {
                text: root.cpuTemp + "°C"
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 11
                font.bold: true
                color: Colors.md3.on_surface
            }
        }

        // GPU Thermals
        RowLayout {
            spacing: 3

            QsText {
                text: "󰢮"
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 12
                color: {
                    if (root.gpuTemp >= 85) return Colors.md3.error;
                    if (root.gpuTemp >= 65) return Colors.md3.tertiary;
                    return Colors.md3.primary;
                }
            }

            QsText {
                text: root.gpuTemp + "°C"
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 11
                font.bold: true
                color: Colors.md3.on_surface
            }
        }
    }
}
