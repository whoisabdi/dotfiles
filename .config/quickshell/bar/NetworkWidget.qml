import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../globals"
import "../ui"

Pill {
    id: root
    clickable: true
    paddingHorizontal: 10
    spacing: 4

    readonly property bool isWifiOn: globalNetworkDaemon ? globalNetworkDaemon.wifiOn : false
    readonly property bool isBtOn: globalNetworkDaemon ? globalNetworkDaemon.btOn : false
    readonly property string ssid: globalNetworkDaemon ? globalNetworkDaemon.currentSsid : "Disconnected"

    onRightClicked: (mouse) => {
        if (typeof globalSettingsApp !== "undefined" && globalSettingsApp) {
            globalSettingsApp.openTab("network")
        }
    }

    RowLayout {
        spacing: 4

        // Wi-Fi Section
        Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 13
            color: wifiMouse.containsMouse ? Qt.alpha(Colors.md3.surface_container_highest, 0.6) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            QsText {
                anchors.centerIn: parent
                text: globalNetworkDaemon ? globalNetworkDaemon.getWifiIcon() : "󰤭"
                color: root.isWifiOn ? Colors.md3.primary : Colors.md3.on_surface_variant
                font.pixelSize: 15
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        if (typeof globalWifiPicker !== "undefined" && globalWifiPicker) {
                            globalWifiPicker.toggle()
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        if (typeof globalSettingsApp !== "undefined" && globalSettingsApp) {
                            globalSettingsApp.openTab("network")
                        }
                    }
                }
            }
        }

        // Bluetooth Section
        Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 13
            color: btMouse.containsMouse ? Qt.alpha(Colors.md3.surface_container_highest, 0.6) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            QsText {
                anchors.centerIn: parent
                text: globalNetworkDaemon ? globalNetworkDaemon.getBtIcon() : "󰂲"
                color: root.isBtOn ? (globalNetworkDaemon && globalNetworkDaemon.btConnected ? Colors.md3.primary : Colors.md3.on_surface) : Colors.md3.on_surface_variant
                font.pixelSize: 15
            }

            // Connection status dot
            Rectangle {
                visible: Boolean(globalNetworkDaemon && globalNetworkDaemon.btConnected)
                width: 5
                height: 5
                radius: 2.5
                color: Colors.md3.primary
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 3
                anchors.rightMargin: 3
            }

            MouseArea {
                id: btMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        if (typeof globalBluetoothPicker !== "undefined" && globalBluetoothPicker) {
                            globalBluetoothPicker.toggle()
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        if (typeof globalSettingsApp !== "undefined" && globalSettingsApp) {
                            globalSettingsApp.openTab("network")
                        }
                    }
                }
            }
        }
    }
}
