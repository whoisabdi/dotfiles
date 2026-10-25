import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import "../globals"
import "../ui"

PanelWindow {
    id: window
    objectName: "btpicker"

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "btpicker"
    exclusiveZone: 0

    color: "transparent"
    visible: false

    HyprlandFocusGrab {
        active: window.visible
        windows: [window]
        onCleared: window.visible = false
    }

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool isPowered: adapter ? adapter.enabled : false
    readonly property bool isScanning: adapter ? adapter.discovering : false

    readonly property var connectedDevices: adapter ? adapter.devices.values.filter(d => d.connected) : []
    readonly property var pairedDevices: adapter ? adapter.devices.values.filter(d => d.paired && !d.connected) : []
    readonly property var availableDevices: adapter ? adapter.devices.values.filter(d => !d.paired && !d.connected && (d.name || d.deviceName)) : []

    property string statusMessage: ""
    property bool statusIsError: false

    function toggle() {
        window.visible = !window.visible
        if (window.visible) {
            if (typeof globalWifiPicker !== "undefined" && globalWifiPicker) {
                globalWifiPicker.visible = false
            }
            if (typeof globalQsPanel !== "undefined" && globalQsPanel) {
                globalQsPanel.visible = false
            }
            statusMessage = ""
        }
    }

    function togglePower() {
        if (adapter) {
            adapter.enabled = !adapter.enabled
        }
    }

    function toggleScan() {
        if (!adapter || !adapter.enabled) return
        adapter.discovering = !adapter.discovering
    }

    function connectDevice(device) {
        if (!device) return
        statusMessage = `Connecting to ${device.name || device.deviceName || device.address}...`
        statusIsError = false
        device.connect()
    }

    function disconnectDevice(device) {
        if (!device) return
        statusMessage = `Disconnecting ${device.name || device.deviceName || device.address}...`
        statusIsError = false
        device.disconnect()
    }

    function pairAndConnect(device) {
        if (!device) return
        statusMessage = `Pairing with ${device.name || device.deviceName || device.address}...`
        statusIsError = false
        device.pair()
        device.trusted = true
        device.connect()
    }

    function forgetDevice(device) {
        if (!device) return
        statusMessage = `Removing ${device.name || device.deviceName || device.address}...`
        statusIsError = false
        Quickshell.execDetached(["bluetoothctl", "remove", device.address])
    }

    function getDeviceIcon(name) {
        let n = (name || "").toLowerCase()
        if (n.includes("headphone") || n.includes("buds") || n.includes("airpod") || n.includes("wh-") || n.includes("wf-") || n.includes("earphone") || n.includes("audio")) return "󰋋";
        if (n.includes("speaker") || n.includes("sound") || n.includes("soundbar") || n.includes("jbl") || n.includes("bose")) return "󰓃";
        if (n.includes("phone") || n.includes("iphone") || n.includes("galaxy") || n.includes("pixel") || n.includes("redmi") || n.includes("xiaomi")) return "󰏲";
        if (n.includes("mouse") || n.includes("mx master") || n.includes("logitech m")) return "󰍽";
        if (n.includes("keyboard") || n.includes("keychron") || n.includes("logitech k")) return "󰌌";
        if (n.includes("controller") || n.includes("gamepad") || n.includes("xbox") || n.includes("dualsense") || n.includes("pro controller")) return "󰊖";
        if (n.includes("watch") || n.includes("band") || n.includes("fitbit") || n.includes("garmin")) return "󰂥";
        return "󰂯";
    }

    IpcHandler {
        target: "btpicker"
        function toggle(): void { window.toggle() }
        function show(): void {
            if (typeof globalWifiPicker !== "undefined" && globalWifiPicker) globalWifiPicker.visible = false
            if (typeof globalQsPanel !== "undefined" && globalQsPanel) globalQsPanel.visible = false
            window.visible = true
        }
        function hide(): void { window.visible = false }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: window.visible = false
    }

    Rectangle {
        id: pickerCard
        anchors.centerIn: parent
        width: 440
        height: 520
        radius: 20
        color: Colors.md3.surface_container_high
        border.color: Colors.md3.outline_variant
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            // Prevent clicks on modal from closing
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: window.isPowered ? Colors.md3.primary_container : Colors.md3.surface_container
                    border.color: window.isPowered ? Colors.md3.primary : Colors.md3.outline_variant
                    border.width: 1

                    QsText {
                        anchors.centerIn: parent
                        text: window.isPowered ? (window.connectedDevices.length > 0 ? "󰂱" : "󰂯") : "󰂲"
                        font.pixelSize: 18
                        color: window.isPowered ? Colors.md3.primary : Colors.md3.on_surface_variant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    QsText {
                        text: "Bluetooth Devices"
                        font.pixelSize: 15
                        font.bold: true
                        color: Colors.md3.on_surface
                    }

                    QsText {
                        text: window.isPowered
                            ? (window.connectedDevices.length > 0 ? `${window.connectedDevices.length} Connected` : "Bluetooth Enabled")
                            : "Bluetooth is Disabled"
                        font.pixelSize: 11
                        color: (window.connectedDevices.length > 0) ? Colors.md3.primary : Colors.md3.on_surface_variant
                        elide: Text.ElideRight
                    }
                }

                // Scan / Discovery Toggle
                Rectangle {
                    visible: window.isPowered
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: scanMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                    border.color: Colors.md3.outline_variant
                    border.width: 1

                    QsText {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.pixelSize: 15
                        color: Colors.md3.primary

                        NumberAnimation on rotation {
                            running: window.isScanning
                            from: 0
                            to: 360
                            duration: 800
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: window.toggleScan()
                    }
                }

                // Power Toggle Switch
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 24
                    radius: 12
                    color: window.isPowered ? Colors.md3.primary : Colors.md3.surface_variant
                    border.color: window.isPowered ? Colors.md3.primary : Colors.md3.outline_variant
                    border.width: 1

                    Rectangle {
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: window.isPowered ? parent.width - width - 3 : 3
                        color: window.isPowered ? Colors.md3.on_primary : Colors.md3.outline
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.togglePower()
                    }
                }
            }

            // Status notification bar (if any)
            Rectangle {
                visible: window.statusMessage.length > 0
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 6
                color: window.statusIsError ? Qt.alpha(Colors.md3.error, 0.2) : Qt.alpha(Colors.md3.primary, 0.15)
                border.color: window.statusIsError ? Colors.md3.error : Colors.md3.primary
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    QsText {
                        text: window.statusIsError ? "󰅚" : "󰛐"
                        font.pixelSize: 12
                        color: window.statusIsError ? Colors.md3.error : Colors.md3.primary
                    }

                    QsText {
                        text: window.statusMessage
                        font.pixelSize: 11
                        color: Colors.md3.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.alpha(Colors.md3.outline_variant, 0.4)
            }

            // Main Scroll Area for Device Lists
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: pickerCard.width - 32
                    spacing: 14

                    // Disabled State Banner
                    Rectangle {
                        visible: !window.isPowered
                        Layout.fillWidth: true
                        implicitHeight: 90
                        radius: 12
                        color: Colors.md3.surface_container

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            QsText {
                                text: "󰂲"
                                font.pixelSize: 28
                                color: Colors.md3.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                            QsText {
                                text: "Bluetooth is turned off"
                                font.pixelSize: 13
                                font.bold: true
                                color: Colors.md3.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // 1. CONNECTED DEVICES
                    ColumnLayout {
                        visible: window.isPowered && window.connectedDevices.length > 0
                        Layout.fillWidth: true
                        spacing: 6

                        QsText {
                            text: "CONNECTED"
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.md3.primary
                        }

                        Repeater {
                            model: window.connectedDevices

                            delegate: Rectangle {
                                required property BluetoothDevice modelData
                                Layout.fillWidth: true
                                implicitHeight: 48
                                radius: 10
                                color: Qt.alpha(Colors.md3.primary, 0.12)
                                border.color: Qt.alpha(Colors.md3.primary, 0.3)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    QsText {
                                        text: window.getDeviceIcon(modelData.name || modelData.deviceName)
                                        font.pixelSize: 16
                                        color: Colors.md3.primary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        QsText {
                                            text: modelData.name || modelData.deviceName || modelData.address
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.md3.on_surface
                                            elide: Text.ElideRight
                                        }

                                        QsText {
                                            text: modelData.batteryAvailable ? `Connected • ${Math.round(modelData.battery * 100)}% Battery` : "Connected"
                                            font.pixelSize: 10
                                            color: Colors.md3.primary
                                        }
                                    }

                                    // Disconnect Button
                                    MouseArea {
                                        implicitWidth: 26; implicitHeight: 26
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.disconnectDevice(modelData)

                                        Rectangle {
                                            anchors.fill: parent; radius: 13
                                            color: parent.containsMouse ? Qt.alpha(Colors.md3.error, 0.2) : "transparent"
                                            QsText { anchors.centerIn: parent; text: "󰅖"; font.pixelSize: 13; color: Colors.md3.error }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 2. PAIRED DEVICES
                    ColumnLayout {
                        visible: window.isPowered && window.pairedDevices.length > 0
                        Layout.fillWidth: true
                        spacing: 6

                        QsText {
                            text: "PAIRED"
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.md3.on_surface_variant
                        }

                        Repeater {
                            model: window.pairedDevices

                            delegate: Rectangle {
                                required property BluetoothDevice modelData
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: 10
                                color: pairedMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                                border.color: Colors.md3.outline_variant
                                border.width: 1

                                MouseArea {
                                    id: pairedMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.connectDevice(modelData)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    QsText {
                                        text: window.getDeviceIcon(modelData.name || modelData.deviceName)
                                        font.pixelSize: 16
                                        color: Colors.md3.on_surface_variant
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        QsText {
                                            text: modelData.name || modelData.deviceName || modelData.address
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.md3.on_surface
                                            elide: Text.ElideRight
                                        }

                                        QsText {
                                            text: "Paired • Click to connect"
                                            font.pixelSize: 10
                                            color: Colors.md3.on_surface_variant
                                        }
                                    }

                                    // Forget button
                                    MouseArea {
                                        implicitWidth: 26; implicitHeight: 26
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.forgetDevice(modelData)

                                        Rectangle {
                                            anchors.fill: parent; radius: 13
                                            color: parent.containsMouse ? Qt.alpha(Colors.md3.outline, 0.2) : "transparent"
                                            QsText { anchors.centerIn: parent; text: "󰆴"; font.pixelSize: 12; color: Colors.md3.on_surface_variant }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. AVAILABLE / DISCOVERED DEVICES
                    ColumnLayout {
                        visible: window.isPowered && window.availableDevices.length > 0
                        Layout.fillWidth: true
                        spacing: 6

                        QsText {
                            text: "AVAILABLE DEVICES"
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.md3.on_surface_variant
                        }

                        Repeater {
                            model: window.availableDevices

                            delegate: Rectangle {
                                required property BluetoothDevice modelData
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: 10
                                color: availMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                                border.color: Colors.md3.outline_variant
                                border.width: 1

                                MouseArea {
                                    id: availMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.pairAndConnect(modelData)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    QsText {
                                        text: window.getDeviceIcon(modelData.name || modelData.deviceName)
                                        font.pixelSize: 16
                                        color: Colors.md3.on_surface_variant
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        QsText {
                                            text: modelData.name || modelData.deviceName || modelData.address
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.md3.on_surface
                                            elide: Text.ElideRight
                                        }

                                        QsText {
                                            text: "Click to pair & connect"
                                            font.pixelSize: 10
                                            color: Colors.md3.on_surface_variant
                                        }
                                    }

                                    QsText {
                                        text: "󰐕"
                                        font.pixelSize: 14
                                        color: Colors.md3.primary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
