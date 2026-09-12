import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../globals"
import "../ui"

Pill {
    id: root
    clickable: true
    paddingHorizontal: 10
    spacing: 8

    property string cpuUsage: "..."
    property string memUsage: "..."
    property int cpuVal: 0

    Process {
        id: btopProc
        command: ["kitty", "--class", "btop", "-e", "btop"]
    }

    Process {
        id: autoCpuProc
        command: ["auto-cpufreq-gtk"]
    }

    onClicked: btopProc.running = true
    onRightClicked: autoCpuProc.running = true

    Process {
        id: statsProc
        command: ["/home/nightwing/.config/quickshell/scripts/sys_stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split("|")
                if (parts.length >= 2) {
                    root.cpuUsage = parts[0]
                    root.memUsage = parts[1]
                    root.cpuVal = parseInt(parts[0]) || 0
                }
            }
        }
    }

    Component.onCompleted: statsProc.running = true

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: statsProc.running = true
    }

    RowLayout {
        spacing: 4
        QsText {
            text: "󰍛"
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 13
            color: root.cpuVal > 75 ? Colors.md3.error : Colors.md3.primary
        }
        QsText {
            text: root.cpuUsage
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 11
            font.bold: true
            color: Colors.md3.on_surface
        }
    }

    RowLayout {
        spacing: 4
        QsText {
            text: "󰘚"
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 13
            color: Colors.md3.secondary
        }
        QsText {
            text: root.memUsage
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 11
            font.bold: true
            color: Colors.md3.on_surface
        }
    }
}
