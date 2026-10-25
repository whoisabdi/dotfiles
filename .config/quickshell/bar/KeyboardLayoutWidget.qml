pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../globals"
import "../ui"

MouseArea {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    property string rawLayout: "English (US)"
    property string mainKbName: "at-translated-set-2-keyboard"

    readonly property string shortCode: {
        let m = rawLayout.match(/\((.*?)\)/)
        if (m && m[1]) return m[1].toUpperCase()
        if (rawLayout.toLowerCase().includes("english")) return "US"
        return rawLayout.slice(0, 2).toUpperCase()
    }

    Process {
        id: initProc
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let j = JSON.parse(text)
                    if (j.keyboards && j.keyboards.length > 0) {
                        let kb = j.keyboards.find(k => k.main) || j.keyboards[0]
                        if (kb) {
                            root.mainKbName = kb.name || root.mainKbName
                            if (kb.active_keymap) {
                                root.rawLayout = kb.active_keymap
                            }
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: switchProc
        command: ["hyprctl", "switchxkblayout", root.mainKbName, "next"]
    }

    onClicked: {
        switchProc.running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                let parts = event.data.split(",")
                if (parts.length > 1) {
                    if (parts[0].indexOf("hl-virtual-") === 0) return
                    root.rawLayout = parts[1].trim()
                }
            } else if (event.name === "configreloaded") {
                initProc.running = true
            }
        }
    }

    RowLayout {
        id: layout
        spacing: 5
        anchors.fill: parent

        QsText {
            text: "󰌌"
            font.pixelSize: 13
            color: Colors.md3.primary
        }

        QsText {
            text: root.shortCode
            font.pixelSize: 12
            font.bold: true
            color: root.containsMouse ? Colors.md3.primary : Colors.md3.on_surface
        }
    }
}
