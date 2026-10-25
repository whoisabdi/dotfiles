import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../globals"
import "../ui"

PanelWindow {
    id: root
    required property var screen

    WlrLayershell.namespace: "bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool hasFullscreen: monitor?.activeWorkspace?.hasFullscreen ?? false

    property real compactState: hasFullscreen ? 1 : 0
    Behavior on compactState {
        SmoothedAnimation { velocity: 8 }
    }

    anchors { top: true; left: true; right: true }
    implicitHeight: 48
    color: "transparent"
    exclusiveZone: hasFullscreen ? 0 : implicitHeight

    mask: Region {
        width: root.width
        height: root.exclusiveZone
    }

    Rectangle {
        id: contentArea
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.bottomMargin: 6
        anchors.topMargin: 6 - (root.implicitHeight + 12) * root.compactState
        color: "transparent"
        opacity: 1 - root.compactState

        // 1. Center Section (Media Player)
        RowLayout {
            id: centerSection
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            z: 10

            MediaWidget {
                id: mediaWidget
            }
        }

        // 2. Right Section (Status & Indicators)
        RowLayout {
            id: rightSection
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 8
            z: 5

            // Tray Pill
            TrayWidget {}

            // Network Pill
            NetworkWidget {}

            // Hardware & Input Status Pill (Backlight, Volume, Keyboard)
            Pill {
                spacing: 12
                paddingHorizontal: 12
                BacklightWidget {}
                VolumeWidget {}
                KeyboardLayoutWidget {}
            }

            // Power & Time Pill (Battery & Clock)
            Pill {
                spacing: 12
                paddingHorizontal: 12
                BatteryWidget {}
                ClockWidget {}
            }

            // Quick Settings Toggle Button
            ArchWidget {}
        }

        // 3. Left Section - Strictly bounded by centerSection.left so it never overlaps!
        RowLayout {
            id: leftSection
            anchors.left: parent.left
            anchors.right: centerSection.left
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 8
            clip: true
            z: 5

            // Workspace Pill
            Pill {
                id: wsPill
                paddingHorizontal: 8
                WorkspacesWidget {
                    id: workspacesWidget
                }
            }

            // Taskbar Pill (with dynamic max width & scrolling)
            Pill {
                id: taskbarPill
                paddingHorizontal: 6
                visible: taskbarWidget.hasItems
                Layout.maximumWidth: Math.max(60, leftSection.width - wsPill.width - (sysStatsWidget.visiblePillsWidth > 0 ? sysStatsWidget.visiblePillsWidth + 16 : 0) - 16)
                clip: true

                TaskbarWidget {
                    id: taskbarWidget
                }
            }

            // System Resources & Thermals (Dynamically adapts based on availableSpace)
            SysStatsWidget {
                id: sysStatsWidget
                availableSpace: leftSection.width - wsPill.width - (taskbarPill.visible ? taskbarPill.width + 8 : 0) - 16
            }

            // Elastic spacer to keep left pills neatly packed against the left edge
            Item {
                Layout.fillWidth: true
            }
        }
    }
}
