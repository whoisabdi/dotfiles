import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../globals"
import "../ui"

ScrollView {
    id: scrollRoot
    required property var rootApp
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        parent: scrollRoot
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 4
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Colors.md3.primary
            opacity: parent.hovered || parent.pressed ? 0.8 : 0.35
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        background: Rectangle { implicitWidth: 4; color: "transparent" }
    }

    ColumnLayout {
        width: scrollRoot.availableWidth - 12
        spacing: 20

        QsText { text: "Network & Bluetooth"; font.pixelSize: 24; font.bold: true; color: Colors.md3.on_surface }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 16

            // 1. Wi-Fi Master Switch
            Rectangle {
                id: wifiCard
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1

                property bool isWifiOn: globalNetworkDaemon ? globalNetworkDaemon.wifiOn : false

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 14

                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        QsText {
                            anchors.centerIn: parent
                            text: "󰤨"
                            font.pixelSize: 26
                            color: wifiCard.isWifiOn ? Colors.md3.primary : Colors.md3.on_surface_variant
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "Wi-Fi"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: wifiCard.isWifiOn ? "Enabled" : "Disabled"; font.pixelSize: 12; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 48; Layout.preferredHeight: 24; radius: 12
                        color: wifiCard.isWifiOn ? Colors.md3.primary : Colors.md3.surface_variant
                        border.color: wifiCard.isWifiOn ? Colors.md3.primary : Colors.md3.outline_variant
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: if (globalNetworkDaemon) globalNetworkDaemon.toggleWifi()
                        }

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: wifiCard.isWifiOn ? Colors.md3.on_primary : Colors.md3.outline
                            anchors.verticalCenter: parent.verticalCenter
                            x: wifiCard.isWifiOn ? parent.width - width - 3 : 3
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }

            // 2. Bluetooth Master Switch
            Rectangle {
                id: btCard
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1

                property bool isBtOn: globalNetworkDaemon ? globalNetworkDaemon.btOn : false

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 14

                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        QsText {
                            anchors.centerIn: parent
                            text: "󰂯"
                            font.pixelSize: 26
                            color: btCard.isBtOn ? Colors.md3.primary : Colors.md3.on_surface_variant
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "Bluetooth"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: btCard.isBtOn ? "Enabled" : "Disabled"; font.pixelSize: 12; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 48; Layout.preferredHeight: 24; radius: 12
                        color: btCard.isBtOn ? Colors.md3.primary : Colors.md3.surface_variant
                        border.color: btCard.isBtOn ? Colors.md3.primary : Colors.md3.outline_variant
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: if (globalNetworkDaemon) globalNetworkDaemon.toggleBt()
                        }

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: btCard.isBtOn ? Colors.md3.on_primary : Colors.md3.outline
                            anchors.verticalCenter: parent.verticalCenter
                            x: btCard.isBtOn ? parent.width - width - 3 : 3
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }
        }

        // Active Connection Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            QsText { text: "Current Connection"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

            Rectangle {
                id: connCard
                Layout.fillWidth: true; Layout.preferredHeight: 64; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1

                property string ssid: globalNetworkDaemon ? globalNetworkDaemon.currentSsid : "Disconnected"

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 14

                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        QsText {
                            anchors.centerIn: parent
                            text: connCard.ssid !== "Disconnected" && connCard.ssid !== "Checking..." ? "󰤨" : "󰤭"
                            font.pixelSize: 24
                            color: Colors.md3.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: connCard.ssid; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: connCard.ssid !== "Disconnected" && connCard.ssid !== "Checking..." ? "Connected via NetworkManager" : "No active network"; font.pixelSize: 12; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }
        }

        // Advanced Network Tools
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            QsText { text: "Advanced System Tools"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

            Process { id: nmEditorProc; command: ["nm-connection-editor"] }
            Process { id: nmtuiProc; command: ["kitty", "--class", "settings-floating", "-e", "nmtui"] }

            // 1. Full GUI Connection Editor
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 64; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { rootApp.visible = false; nmEditorProc.running = true }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 14

                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        QsText {
                            anchors.centerIn: parent
                            text: "󰢩"
                            font.pixelSize: 24
                            color: Colors.md3.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "Network Connections (GUI Editor)"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: "Configure static IPs, Wi-Fi 802.1X, VPNs, and proxies in nm-connection-editor"; font.pixelSize: 12; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    QsText { text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
                }
            }

            // 2. Terminal TUI
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 64; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { rootApp.visible = false; nmtuiProc.running = true }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 14

                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        QsText {
                            anchors.centerIn: parent
                            text: "󱛇"
                            font.pixelSize: 24
                            color: Colors.md3.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "Manage Saved Networks (Terminal TUI)"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: "Launch nmtui to quickly edit network configurations"; font.pixelSize: 12; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    QsText { text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 20 }
    }
}
