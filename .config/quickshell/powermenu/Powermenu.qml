import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../globals"
import "../ui"

PanelWindow {
    id: window
    objectName: "powermenu"

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "powermenu"
    exclusionMode: ExclusionMode.Ignore

    color: Qt.rgba(0, 0, 0, 0.65)
    visible: false

    property string uptimeStr: "Up..."
    property int selectedIndex: 0

    readonly property var powerActions: [
        { name: "Lock", icon: "", key: "L", command: "hyprlock", color: Colors.md3.primary },
        { name: "Sleep", icon: "󰤄", key: "U", command: "systemctl suspend", color: Colors.md3.secondary },
        { name: "Logout", icon: "󰍃", key: "E", command: "uwsm stop", color: Colors.md3.tertiary },
        { name: "Reboot", icon: "󰑓", key: "R", command: "systemctl reboot", color: Colors.md3.primary },
        { name: "Shutdown", icon: "󰐥", key: "S", command: "systemctl poweroff", color: Colors.md3.error }
    ]

    function toggle() {
        window.visible = !window.visible
        if (window.visible) {
            selectedIndex = 0
            uptimeProc.running = true
            bgMouse.forceActiveFocus()
        }
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p | sed 's/up //g'"]
        stdout: StdioCollector {
            onStreamFinished: window.uptimeStr = text.trim()
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { window.toggle() }
        function show(): void {
            window.visible = true
            selectedIndex = 0
            uptimeProc.running = true
            bgMouse.forceActiveFocus()
        }
        function hide(): void { window.visible = false }
    }

    MouseArea {
        id: bgMouse
        anchors.fill: parent
        onClicked: window.visible = false

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                window.visible = false
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                window.selectedIndex = (window.selectedIndex - 1 + window.powerActions.length) % window.powerActions.length
                event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                window.selectedIndex = (window.selectedIndex + 1) % window.powerActions.length
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (window.selectedIndex >= 0 && window.selectedIndex < window.powerActions.length) {
                    executeAction(window.powerActions[window.selectedIndex].command)
                }
                event.accepted = true
            } else if (event.key === Qt.Key_L) {
                executeAction("hyprlock")
            } else if (event.key === Qt.Key_S) {
                executeAction("systemctl poweroff")
            } else if (event.key === Qt.Key_R) {
                executeAction("systemctl reboot")
            } else if (event.key === Qt.Key_U) {
                executeAction("systemctl suspend")
            } else if (event.key === Qt.Key_E) {
                executeAction("uwsm stop")
            }
        }
    }

    Process {
        id: execProc
    }

    function executeAction(cmd) {
        window.visible = false
        execProc.command = ["sh", "-c", cmd]
        execProc.running = true
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 28

        // Header: User & Uptime Info
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64; height: 64; radius: 32
                color: Colors.md3.primary_container

                QsText {
                    anchors.centerIn: parent
                    text: "󰣇"
                    font.pixelSize: 32
                    color: Colors.md3.on_primary_container
                }
            }

            QsText {
                Layout.alignment: Qt.AlignHCenter
                text: Quickshell.env("USER") ? Quickshell.env("USER").toUpperCase() : "SESSION"
                font.pixelSize: 18
                font.bold: true
                color: Colors.md3.on_surface
            }

            QsText {
                Layout.alignment: Qt.AlignHCenter
                text: "Uptime: " + window.uptimeStr
                font.pixelSize: 12
                color: Colors.md3.on_surface_variant
            }
        }

        // Power Action Buttons Row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Repeater {
                model: window.powerActions

                delegate: Item {
                    id: delegateItem
                    width: 120
                    height: 140

                    required property var modelData
                    required property int index

                    property bool isSelected: window.selectedIndex === index
                    property bool isHovered: mouseArea.containsMouse
                    property bool isHighlighted: isSelected || isHovered

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: window.selectedIndex = index
                        onClicked: executeAction(modelData.command)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: delegateItem.isHighlighted ? modelData.color : Colors.md3.surface_container_high
                        border.color: delegateItem.isHighlighted ? modelData.color : Colors.md3.outline_variant
                        border.width: delegateItem.isSelected ? 2 : 1
                        scale: delegateItem.isHighlighted ? 1.06 : 1.0

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            QsText {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                font.pixelSize: 36
                                color: delegateItem.isHighlighted ? Colors.md3.surface : modelData.color
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 2

                                QsText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.name
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: delegateItem.isHighlighted ? Colors.md3.surface : Colors.md3.on_surface
                                }

                                QsText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: `[${modelData.key}]`
                                    font.pixelSize: 10
                                    color: delegateItem.isHighlighted ? Qt.alpha(Colors.md3.surface, 0.7) : Colors.md3.on_surface_variant
                                }
                            }
                        }
                    }
                }
            }
        }

        QsText {
            Layout.alignment: Qt.AlignHCenter
            text: "Press [Esc] to cancel"
            font.pixelSize: 11
            color: Qt.alpha(Colors.md3.on_surface_variant, 0.6)
        }
    }
}
