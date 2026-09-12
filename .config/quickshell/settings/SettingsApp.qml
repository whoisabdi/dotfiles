import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../globals"
import "../ui"

PanelWindow {
    id: window
    objectName: "settingsapp"

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "settingsapp"
    exclusiveZone: 0

    color: "transparent"
    visible: false

    property string currentTab: "network"

    function openTab(targetTab) {
        currentTab = targetTab
        window.visible = true
        bgMouse.forceActiveFocus()
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            window.visible = !window.visible
            if (window.visible) bgMouse.forceActiveFocus()
        }
        function openTab(name: string): void {
            window.openTab(name)
        }
        function show(): void {
            window.visible = true
            bgMouse.forceActiveFocus()
        }
        function hide(): void { window.visible = false }
    }

    MouseArea {
        id: bgMouse
        anchors.fill: parent
        onClicked: window.visible = false
        Keys.onEscapePressed: window.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 880; height: 640
        color: Colors.md3.surface; radius: 18
        border.color: Colors.md3.outline_variant; border.width: 1
        clip: true

        MouseArea { anchors.fill: parent }

        RowLayout {
            anchors.fill: parent; spacing: 0

            // Sidebar (with matching rounded left corners)
            Rectangle {
                Layout.preferredWidth: 220; Layout.fillHeight: true
                color: Colors.md3.surface_variant
                topLeftRadius: 18
                bottomLeftRadius: 18
                topRightRadius: 0
                bottomRightRadius: 0

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Colors.md3.outline_variant
                }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 8

                    QsText { text: "Settings"; font.pixelSize: 22; font.bold: true; color: Colors.md3.on_surface; Layout.bottomMargin: 16; Layout.leftMargin: 8 }

                    SettingsTabButton { title: "Network"; icon: "󰤨"; isActive: window.currentTab === "network"; onClicked: window.currentTab = "network" }
                    SettingsTabButton { title: "Appearance"; icon: "󰏘"; isActive: window.currentTab === "appearance"; onClicked: window.currentTab = "appearance" }
                    SettingsTabButton { title: "Audio"; icon: "󰕾"; isActive: window.currentTab === "audio"; onClicked: window.currentTab = "audio" }
                    SettingsTabButton { title: "System"; icon: "󰌢"; isActive: window.currentTab === "system"; onClicked: window.currentTab = "system" }

                    Item { Layout.fillHeight: true }
                }
            }

            // Tab Content Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    anchors.rightMargin: 12
                    currentIndex: {
                        if (window.currentTab === "appearance") return 1;
                        if (window.currentTab === "audio") return 2;
                        if (window.currentTab === "system") return 3;
                        return 0;
                    }
                    NetworkTab { rootApp: window }
                    AppearanceTab { rootApp: window }
                    AudioTab { rootApp: window }
                    SystemTab { rootApp: window }
                }
            }
        }
    }
}
