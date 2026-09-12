import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../globals"
import "../ui"

PanelWindow {
    id: root
    required property var screen

    WlrLayershell.namespace: "bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    implicitHeight: 48
    color: "transparent"
    exclusiveZone: implicitHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        color: "transparent"

        // Left Section
        RowLayout {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 8

            // System Resources Pill (CPU & RAM)
            SysStatsWidget {}

            // Workspace Pill
            Pill {
                paddingHorizontal: 8
                WorkspacesWidget {}
            }

            // Taskbar Pill
            Pill {
                id: taskbarPill
                paddingHorizontal: 6
                visible: taskbarWidget.hasItems
                TaskbarWidget {
                    id: taskbarWidget
                }
            }
        }

        // Center Section
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            MediaWidget {}
        }

        // Right Section
        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 8

            // Tray Pill
            TrayWidget {}

            // Network Pill
            NetworkWidget {}

            // Hardware Status Pill (Backlight & Volume)
            Pill {
                spacing: 12
                paddingHorizontal: 12
                BacklightWidget {}
                VolumeWidget {}
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
    }
}
