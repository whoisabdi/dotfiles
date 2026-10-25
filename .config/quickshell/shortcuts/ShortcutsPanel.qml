pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../globals"
import "../ui"

PanelWindow {
    id: window
    objectName: "shortcuts"

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "shortcuts"
    exclusiveZone: 0

    color: "transparent"
    visible: false

    HyprlandFocusGrab {
        active: window.visible
        windows: [window]
        onCleared: window.visible = false
    }

    function toggle() {
        window.visible = !window.visible
        if (window.visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
        }
    }

    IpcHandler {
        target: "shortcuts"
        function toggle(): void { window.toggle() }
        function show(): void {
            window.visible = true
            searchField.text = ""
            searchField.forceActiveFocus()
        }
        function hide(): void { window.visible = false }
    }

    readonly property var shortcutCategories: [
        {
            category: "Applications & System",
            icon: "󰄛",
            items: [
                { key: "SUPER", desc: "Toggle App Launcher" },
                { key: "SUPER + T", desc: "Open Terminal (Kitty)" },
                { key: "SUPER + C", desc: "Open Code Editor (VSCodium)" },
                { key: "SUPER + E", desc: "Open File Manager (Nautilus)" },
                { key: "SUPER + F", desc: "Open Web Browser (Chrome)" },
                { key: "Ctrl + Shift + Esc", desc: "System Monitor (btop)" },
                { key: "SUPER + L", desc: "Lock Screen (Hyprlock)" },
                { key: "Alt + Esc", desc: "Power & Session Menu" },
                { key: "SUPER + A", desc: "Toggle Control Center" },
                { key: "SUPER + I", desc: "Toggle Settings App" },
                { key: "SUPER + /", desc: "This Shortcuts Cheat Sheet" }
            ]
        },
        {
            category: "Window Management",
            icon: "󰨡",
            items: [
                { key: "Alt + F4", desc: "Close Active Window" },
                { key: "SUPER + V", desc: "Toggle Floating Window" },
                { key: "SUPER + Esc", desc: "Toggle True Fullscreen" },
                { key: "SUPER + Shift + F", desc: "Toggle Maximized Window" },
                { key: "SUPER + J", desc: "Toggle Split Orientation (Dwindle)" },
                { key: "Alt + Tab", desc: "Cycle Active Windows" },
                { key: "SUPER + Arrows", desc: "Move Focus Direction" },
                { key: "SUPER + Shift + Arrows", desc: "Swap Window Direction" }
            ]
        },
        {
            category: "Resizing & Manipulation",
            icon: "󰩨",
            items: [
                { key: "SUPER + Ctrl + Arrows", desc: "Resize Active Window (Smooth)" },
                { key: "SUPER + Ctrl + HJKL", desc: "Vim-Style Active Window Resize" },
                { key: "SUPER + Left Mouse", desc: "Drag & Move Floating Window" },
                { key: "SUPER + Right Mouse", desc: "Interactive Resize Window" }
            ]
        },
        {
            category: "Workspaces & Scratchpad",
            icon: "󰍹",
            items: [
                { key: "SUPER + 1..9, 0", desc: "Switch to Workspace 1..10" },
                { key: "SUPER + Shift + 1..9", desc: "Move Window to Workspace 1..10" },
                { key: "SUPER + Shift + S", desc: "Toggle Magic Scratchpad" },
                { key: "SUPER + S", desc: "Send Window to Magic Scratchpad" },
                { key: "SUPER + Scroll", desc: "Cycle Workspaces Forward / Back" }
            ]
        },
        {
            category: "Media & Utilities",
            icon: "󰎆",
            items: [
                { key: "Fn Vol Up / Down", desc: "Adjust Volume with Reactive OSD" },
                { key: "Fn Mute / MicMute", desc: "Toggle Audio / Microphone Mute" },
                { key: "Fn Brightness", desc: "Adjust Display Brightness with OSD" },
                { key: "Fn Play / Pause", desc: "Toggle MPRIS Media Playback" },
                { key: "Fn Next / Prev", desc: "Skip / Previous Audio Track" },
                { key: "Alt + S", desc: "Screenshot Selected Area" },
                { key: "Alt + Shift + S", desc: "Screenshot Entire Screen" },
                { key: "Alt + Shift + P", desc: "Color Picker (Hyprpicker)" },
                { key: "Ctrl + Shift + W", desc: "Randomize Wallpaper" }
            ]
        }
    ]

    MouseArea {
        anchors.fill: parent
        onClicked: window.visible = false
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(window.width - 48, 860)
        height: Math.min(window.height - 64, 580)
        radius: 20
        color: Colors.md3.surface_container_high
        border.color: Colors.md3.outline_variant
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            // Prevent clicks on the card from closing modal
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    QsText {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.pixelSize: 26
                        color: Colors.md3.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QsText {
                        text: "Keyboard Shortcuts"
                        font.pixelSize: 18
                        font.bold: true
                        color: Colors.md3.on_surface
                    }
                    QsText {
                        text: "Hyprland & Quickshell keybinding cheat sheet"
                        font.pixelSize: 12
                        color: Colors.md3.on_surface_variant
                    }
                }

                // Search box
                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.preferredHeight: 36
                    radius: 18
                    color: Colors.md3.surface_container
                    border.color: Colors.md3.outline_variant
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        QsText {
                            text: "󰍉"
                            font.pixelSize: 14
                            color: Colors.md3.on_surface_variant
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Colors.md3.on_surface
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true

                            Text {
                                text: "Filter shortcuts..."
                                color: Colors.md3.on_surface_variant
                                opacity: 0.6
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }

                            Keys.onEscapePressed: (event) => {
                                window.visible = false
                                event.accepted = true
                            }
                        }
                    }
                }

                // Close button
                MouseArea {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.visible = false

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: parent.containsMouse ? Qt.alpha(Colors.md3.surface_variant, 0.6) : "transparent"
                        QsText {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.pixelSize: 16
                            color: Colors.md3.on_surface_variant
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.alpha(Colors.md3.outline_variant, 0.4)
            }

            // Main Scrollable List
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: card.width - 48
                    spacing: 20

                    Repeater {
                        model: window.shortcutCategories

                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10

                            readonly property var filteredItems: {
                                let query = searchField.text.trim().toLowerCase()
                                if (!query) return modelData.items
                                return modelData.items.filter(item => {
                                    return item.key.toLowerCase().includes(query) ||
                                           item.desc.toLowerCase().includes(query) ||
                                           modelData.category.toLowerCase().includes(query)
                                })
                            }

                            visible: filteredItems.length > 0

                            // Category Header
                            RowLayout {
                                spacing: 8
                                QsText {
                                    text: modelData.icon
                                    font.pixelSize: 16
                                    color: Colors.md3.primary
                                }
                                QsText {
                                    text: modelData.category
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Colors.md3.primary
                                }
                            }

                            // Grid of Keybinds in this Category
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 16
                                rowSpacing: 8

                                Repeater {
                                    model: filteredItems

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        radius: 8
                                        color: Qt.alpha(Colors.md3.surface_container, 0.7)
                                        border.color: Qt.alpha(Colors.md3.outline_variant, 0.3)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 12

                                            // Key badge
                                            Rectangle {
                                                implicitWidth: keyText.implicitWidth + 14
                                                implicitHeight: 24
                                                radius: 6
                                                color: Qt.alpha(Colors.md3.primary, 0.15)
                                                border.color: Qt.alpha(Colors.md3.primary, 0.4)
                                                border.width: 1

                                                QsText {
                                                    id: keyText
                                                    anchors.centerIn: parent
                                                    text: modelData.key
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Colors.md3.primary
                                                }
                                            }

                                            // Description
                                            QsText {
                                                Layout.fillWidth: true
                                                text: modelData.desc
                                                font.pixelSize: 12
                                                color: Colors.md3.on_surface
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer tip
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                QsText {
                    text: "󰋼"
                    font.pixelSize: 13
                    color: Colors.md3.on_surface_variant
                }
                QsText {
                    text: "Press ESC or click outside to dismiss • Trigger with SUPER + /"
                    font.pixelSize: 11
                    color: Colors.md3.on_surface_variant
                }
            }
        }
    }
}
