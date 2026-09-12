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
    objectName: "btpicker"

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "btpicker"
    exclusiveZone: 0

    color: "transparent"
    visible: false

    property var connectedDevices: []
    property var pairedDevices: []
    property var availableDevices: []
    property bool isScanning: false
    property bool isDiscoverable: false
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
            refreshDevices()
        } else {
            statusMessage = ""
        }
    }

    function refreshDevices() {
        if (!globalNetworkDaemon || !globalNetworkDaemon.btOn) return
        statusMessage = "Loading devices..."
        statusIsError = false
        deviceFetchProcess.running = true
        discoverableCheckProc.running = true
    }

    function toggleDiscoverable() {
        if (!globalNetworkDaemon || !globalNetworkDaemon.btOn) return
        toggleDiscoverableProc.running = true
    }

    function startScan() {
        if (!globalNetworkDaemon || !globalNetworkDaemon.btOn) return
        isScanning = true
        statusMessage = "Scanning for nearby devices..."
        statusIsError = false
        scanProcess.running = true
    }

    function stopScan() {
        isScanning = false
        stopScanProcess.running = true
    }

    function connectDevice(mac, name) {
        statusMessage = `Connecting to ${name || mac}...`
        statusIsError = false
        connectProcess.command = ["bluetoothctl", "connect", mac]
        connectProcess.running = true
    }

    function disconnectDevice(mac, name) {
        statusMessage = `Disconnecting ${name || mac}...`
        statusIsError = false
        disconnectProcess.command = ["bluetoothctl", "disconnect", mac]
        disconnectProcess.running = true
    }

    function pairAndConnect(mac, name) {
        statusMessage = `Pairing with ${name || mac}...`
        statusIsError = false
        pairProcess.command = ["sh", "-c", `bluetoothctl agent NoInputNoOutput && bluetoothctl default-agent && bluetoothctl pair ${mac} && bluetoothctl trust ${mac} && bluetoothctl connect ${mac}`]
        pairProcess.running = true
    }

    function forgetDevice(mac, name) {
        statusMessage = `Removing ${name || mac}...`
        statusIsError = false
        forgetProcess.command = ["bluetoothctl", "remove", mac]
        forgetProcess.running = true
    }

    function getDeviceIcon(name, iconType) {
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
            if (typeof globalWifiPicker !== "undefined" && globalWifiPicker) {
                globalWifiPicker.visible = false
            }
            if (typeof globalQsPanel !== "undefined" && globalQsPanel) {
                globalQsPanel.visible = false
            }
            window.visible = true
            window.refreshDevices()
        }
        function hide(): void { window.visible = false }
    }

    // Process to fetch paired and connected devices
    Process {
        id: deviceFetchProcess
        command: ["sh", "-c", "
            PAIRED=$(bluetoothctl devices Paired 2>/dev/null);
            CONNECTED=$(bluetoothctl devices Connected 2>/dev/null);
            echo '===CONNECTED===';
            for mac in $(echo \"$CONNECTED\" | awk '{print $2}'); do
                if [ -n \"$mac\" ]; then
                    INFO=$(bluetoothctl info \"$mac\" 2>/dev/null);
                    NAME=$(echo \"$INFO\" | grep '^[[:space:]]*Alias:' | head -n 1 | sed 's/^[[:space:]]*Alias:[[:space:]]*//');
                    if [ -z \"$NAME\" ]; then NAME=$(echo \"$INFO\" | grep '^[[:space:]]*Name:' | head -n 1 | sed 's/^[[:space:]]*Name:[[:space:]]*//'); fi;
                    ICON=$(echo \"$INFO\" | grep '^[[:space:]]*Icon:' | head -n 1 | sed 's/^[[:space:]]*Icon:[[:space:]]*//');
                    BATTERY=$(echo \"$INFO\" | grep -i 'Battery Percentage' | head -n 1 | grep -oP '\\(\\K[0-9]+(?=\\))');
                    echo \"$mac|$NAME|$ICON|$BATTERY\";
                fi
            done
            echo '===PAIRED===';
            for mac in $(echo \"$PAIRED\" | awk '{print $2}'); do
                if [ -n \"$mac\" ]; then
                    NAME=$(echo \"$PAIRED\" | grep \"$mac\" | cut -d' ' -f3-);
                    echo \"$mac|$NAME\";
                fi
            done
        "]
        stdout: StdioCollector {
            onStreamFinished: {
                let textContent = text.replace(/\r/g, "")
                let connSection = ""
                let pairedSection = ""

                let p1 = textContent.split("===CONNECTED===")
                if (p1.length > 1) {
                    let p2 = p1[1].split("===PAIRED===")
                    connSection = p2[0].trim()
                    if (p2.length > 1) {
                        pairedSection = p2[1].trim()
                    }
                }

                let connected = []
                if (connSection.length > 0) {
                    let lines = connSection.split("\n")
                    for (let line of lines) {
                        let parts = line.trim().split("|")
                        if (parts.length >= 2 && parts[0].length > 0) {
                            connected.push({
                                mac: parts[0],
                                name: parts[1] || parts[0],
                                icon: parts[2] || "",
                                battery: parts[3] || ""
                            })
                        }
                    }
                }

                let connMacs = new Set(connected.map(d => d.mac))
                let paired = []
                if (pairedSection.length > 0) {
                    let lines = pairedSection.split("\n")
                    for (let line of lines) {
                        let parts = line.trim().split("|")
                        if (parts.length >= 2 && parts[0].length > 0) {
                            if (!connMacs.has(parts[0])) {
                                paired.push({
                                    mac: parts[0],
                                    name: parts[1] || parts[0]
                                })
                            }
                        }
                    }
                }

                window.connectedDevices = connected
                window.pairedDevices = paired

                if (window.statusMessage === "Loading devices...") {
                    window.statusMessage = ""
                }
                if (globalNetworkDaemon) globalNetworkDaemon.refresh()
            }
        }
    }

    Process {
        id: scanProcess
        command: ["sh", "-c", "bluetoothctl --timeout 8 scan on"]
        onExited: {
            window.isScanning = false
            window.refreshDevices()
        }
    }

    Process {
        id: stopScanProcess
        command: ["bluetoothctl", "scan", "off"]
        onExited: window.refreshDevices()
    }

    Process {
        id: discoverableCheckProc
        command: ["sh", "-c", "if bluetoothctl show 2>/dev/null | grep -q 'Discoverable: yes'; then echo '1'; else echo '0'; fi"]
        stdout: StdioCollector {
            onStreamFinished: window.isDiscoverable = (text.trim() === '1')
        }
    }

    Process {
        id: toggleDiscoverableProc
        command: ["sh", "-c", "if bluetoothctl show 2>/dev/null | grep -q 'Discoverable: yes'; then bluetoothctl discoverable off; else bluetoothctl discoverable on && bluetoothctl pairable on; fi"]
        onExited: discoverableCheckProc.running = true
    }

    Process {
        id: connectProcess
        stdout: StdioCollector {
            onStreamFinished: {
                window.statusMessage = "Connected successfully!"
                window.statusIsError = false
                window.refreshDevices()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    window.statusMessage = text.trim().split("\n")[0]
                    window.statusIsError = true
                }
            }
        }
    }

    Process {
        id: disconnectProcess
        onExited: {
            window.statusMessage = "Disconnected"
            window.statusIsError = false
            window.refreshDevices()
        }
    }

    Process {
        id: pairProcess
        stdout: StdioCollector {
            onStreamFinished: {
                window.statusMessage = "Paired & connected successfully!"
                window.statusIsError = false
                window.refreshDevices()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    window.statusMessage = text.trim().split("\n")[0]
                    window.statusIsError = true
                }
            }
        }
    }

    Process {
        id: forgetProcess
        onExited: {
            window.statusMessage = "Device removed"
            window.statusIsError = false
            window.refreshDevices()
        }
    }

    onVisibleChanged: {
        if (visible) {
            bgMouse.forceActiveFocus()
        }
    }

    MouseArea {
        id: bgMouse
        anchors.fill: parent
        focus: true
        onClicked: window.visible = false
        Keys.onEscapePressed: (event) => { window.visible = false; event.accepted = true; }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                window.visible = false
                event.accepted = true
            }
        }
    }

    Rectangle {
        id: pickerModal
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.rightMargin: 12
        width: 380
        height: Math.min(540, mainLayout.implicitHeight + 28)
        radius: 14
        color: Qt.alpha(Colors.md3.surface_container_high, 0.95)
        border.color: Colors.md3.outline_variant
        border.width: 1
        clip: true
        focus: true

        Keys.onEscapePressed: (event) => { window.visible = false; event.accepted = true; }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                window.visible = false
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: bgMouse.forceActiveFocus()
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: globalNetworkDaemon && globalNetworkDaemon.btOn ? Colors.md3.primary_container : Colors.md3.surface_container
                    border.color: globalNetworkDaemon && globalNetworkDaemon.btOn ? Colors.md3.primary : Colors.md3.outline_variant
                    border.width: 1

                    QsText {
                        anchors.centerIn: parent
                        text: globalNetworkDaemon ? globalNetworkDaemon.getBtIcon() : "󰂯"
                        font.pixelSize: 18
                        color: globalNetworkDaemon && globalNetworkDaemon.btOn ? Colors.md3.primary : Colors.md3.on_surface_variant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    QsText {
                        text: "Bluetooth Devices"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.md3.on_surface
                    }

                    QsText {
                        text: (globalNetworkDaemon && globalNetworkDaemon.btOn)
                            ? (window.connectedDevices.length > 0 ? `${window.connectedDevices.length} Connected` : "Bluetooth Enabled")
                            : "Bluetooth is Disabled"
                        font.pixelSize: 11
                        color: (window.connectedDevices.length > 0) ? Colors.md3.primary : Colors.md3.on_surface_variant
                        elide: Text.ElideRight
                    }
                }

                // Scan Button
                Rectangle {
                    visible: globalNetworkDaemon && globalNetworkDaemon.btOn
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: scanMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                    border.color: Colors.md3.outline_variant
                    border.width: 1

                    QsText {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.pixelSize: 14
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
                        onClicked: {
                            if (window.isScanning) {
                                window.stopScan()
                            } else {
                                window.startScan()
                            }
                        }
                    }
                }

                // Master Bluetooth Toggle Switch
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 24
                    radius: 12
                    color: (globalNetworkDaemon && globalNetworkDaemon.btOn) ? Colors.md3.primary : Colors.md3.surface_variant
                    border.color: (globalNetworkDaemon && globalNetworkDaemon.btOn) ? Colors.md3.primary : Colors.md3.outline_variant
                    border.width: 1

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: (globalNetworkDaemon && globalNetworkDaemon.btOn) ? Colors.md3.on_primary : Colors.md3.outline
                        anchors.verticalCenter: parent.verticalCenter
                        x: (globalNetworkDaemon && globalNetworkDaemon.btOn) ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (globalNetworkDaemon) {
                                globalNetworkDaemon.toggleBt()
                                window.refreshDevices()
                            }
                        }
                    }
                }
            }

            // Discoverable (Visibility to other devices) Row
            Rectangle {
                visible: globalNetworkDaemon && globalNetworkDaemon.btOn
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                color: window.isDiscoverable ? Colors.md3.primary_container : Colors.md3.surface_container
                border.color: window.isDiscoverable ? Colors.md3.primary : Colors.md3.outline_variant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    QsText {
                        text: window.isDiscoverable ? "󰂱" : "󰂲"
                        font.pixelSize: 14
                        color: window.isDiscoverable ? Colors.md3.primary : Colors.md3.on_surface_variant
                    }

                    QsText {
                        Layout.fillWidth: true
                        text: window.isDiscoverable ? "PC Visible to Phones & Devices" : "Make PC Discoverable"
                        font.pixelSize: 11
                        font.bold: window.isDiscoverable
                        color: window.isDiscoverable ? Colors.md3.on_primary_container : Colors.md3.on_surface
                    }

                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 18
                        radius: 9
                        color: window.isDiscoverable ? Colors.md3.primary : Colors.md3.surface_variant

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            color: window.isDiscoverable ? Colors.md3.on_primary : Colors.md3.outline
                            anchors.verticalCenter: parent.verticalCenter
                            x: window.isDiscoverable ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.toggleDiscoverable()
                }
            }

            Timer {
                id: btTimer
                interval: 800
                onTriggered: window.refreshDevices()
            }

            // Status Banner
            Rectangle {
                visible: window.statusMessage.length > 0
                Layout.fillWidth: true
                implicitHeight: 26
                radius: 8
                color: window.statusIsError ? Colors.md3.error_container : Colors.md3.primary_container

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    QsText {
                        text: window.statusIsError ? "󰅖" : "󰄬"
                        font.pixelSize: 12
                        color: window.statusIsError ? Colors.md3.on_error_container : Colors.md3.on_primary_container
                    }

                    QsText {
                        Layout.fillWidth: true
                        text: window.statusMessage
                        font.pixelSize: 11
                        font.bold: true
                        color: window.statusIsError ? Colors.md3.on_error_container : Colors.md3.on_primary_container
                        elide: Text.ElideRight
                    }
                }
            }

            // Devices Scrollable List
            ScrollView {
                id: devScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                Layout.minimumHeight: Math.min(320, (window.connectedDevices.length + window.pairedDevices.length + window.availableDevices.length) * 56 + 40)
                clip: true

                ColumnLayout {
                    id: devCol
                    width: devScroll.availableWidth
                    spacing: 10

                    QsText {
                        visible: (!globalNetworkDaemon || !globalNetworkDaemon.btOn)
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 40
                        text: "Turn on Bluetooth to see devices"
                        font.pixelSize: 12
                        font.italic: true
                        color: Colors.md3.on_surface_variant
                    }

                    // 1. CONNECTED DEVICES SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        width: devCol.width
                        visible: (globalNetworkDaemon && globalNetworkDaemon.btOn) && window.connectedDevices.length > 0
                        spacing: 6

                        QsText {
                            text: "CONNECTED"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.md3.primary
                        }

                        Repeater {
                            model: window.connectedDevices
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                width: devCol.width
                                implicitHeight: 52
                                radius: 12
                                color: Qt.alpha(Colors.md3.primary_container, 0.45)
                                border.color: Colors.md3.primary
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    QsText {
                                        text: window.getDeviceIcon(modelData.name)
                                        font.pixelSize: 18
                                        color: Colors.md3.primary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        QsText {
                                            text: modelData.name || modelData.mac
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.md3.on_surface
                                            elide: Text.ElideRight
                                        }
                                        RowLayout {
                                            spacing: 6
                                            QsText {
                                                text: "● Connected"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Colors.md3.primary
                                            }
                                            Rectangle {
                                                visible: Boolean(modelData.battery && modelData.battery.length > 0)
                                                implicitWidth: bText.implicitWidth + 8
                                                implicitHeight: 16
                                                radius: 8
                                                color: Qt.alpha(Colors.md3.primary, 0.18)
                                                border.color: Qt.alpha(Colors.md3.primary, 0.4)
                                                border.width: 1
                                                QsText {
                                                    id: bText
                                                    anchors.centerIn: parent
                                                    text: "󰂁 " + (modelData.battery || "") + "%"
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: Colors.md3.primary
                                                }
                                            }
                                        }
                                    }

                                    // Disconnect Button
                                    Rectangle {
                                        implicitWidth: btDiscText.implicitWidth + 14
                                        implicitHeight: 24
                                        radius: 12
                                        color: btDiscMouse.containsMouse ? Colors.md3.error : Qt.alpha(Colors.md3.error_container, 0.6)
                                        border.color: Colors.md3.error
                                        border.width: 1

                                        QsText {
                                            id: btDiscText
                                            anchors.centerIn: parent
                                            text: "Disconnect"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: btDiscMouse.containsMouse ? Colors.md3.on_error : Colors.md3.error
                                        }

                                        MouseArea {
                                            id: btDiscMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: window.disconnectDevice(modelData.mac, modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 2. PAIRED DEVICES SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        width: devCol.width
                        visible: (globalNetworkDaemon && globalNetworkDaemon.btOn) && window.pairedDevices.length > 0
                        spacing: 6

                        QsText {
                            text: "PAIRED"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.md3.on_surface_variant
                        }

                        Repeater {
                            model: window.pairedDevices
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                width: devCol.width
                                implicitHeight: 52
                                radius: 12
                                color: pMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                                border.color: pMouse.containsMouse ? Colors.md3.outline : Qt.alpha(Colors.md3.outline_variant, 0.5)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    QsText {
                                        text: window.getDeviceIcon(modelData.name)
                                        font.pixelSize: 18
                                        color: Colors.md3.on_surface_variant
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        QsText {
                                            text: modelData.name || modelData.mac
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Colors.md3.on_surface
                                            elide: Text.ElideRight
                                        }
                                        QsText {
                                            text: "Paired (Offline)"
                                            font.pixelSize: 10
                                            color: Colors.md3.on_surface_variant
                                        }
                                    }

                                    RowLayout {
                                        spacing: 4

                                        // Connect Button
                                        Rectangle {
                                            implicitWidth: pConnText.implicitWidth + 14
                                            implicitHeight: 24
                                            radius: 12
                                            color: pConnMouse.containsMouse ? Colors.md3.primary : Colors.md3.primary_container

                                            QsText {
                                                id: pConnText
                                                anchors.centerIn: parent
                                                text: "Connect"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: pConnMouse.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container
                                            }

                                            MouseArea {
                                                id: pConnMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: window.connectDevice(modelData.mac, modelData.name)
                                            }
                                        }

                                        // Forget Button
                                        Rectangle {
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 12
                                            color: pForMouse.containsMouse ? Colors.md3.error_container : "transparent"

                                            QsText {
                                                anchors.centerIn: parent
                                                text: "󰅖"
                                                font.pixelSize: 12
                                                color: pForMouse.containsMouse ? Colors.md3.error : Colors.md3.on_surface_variant
                                            }

                                            MouseArea {
                                                id: pForMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: window.forgetDevice(modelData.mac, modelData.name)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: pMouse
                                    anchors.fill: parent
                                    z: -1
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.connectDevice(modelData.mac, modelData.name)
                                }
                            }
                        }
                    }

                    // 3. AVAILABLE NEARBY DEVICES SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        width: devCol.width
                        visible: (globalNetworkDaemon && globalNetworkDaemon.btOn) && window.availableDevices.length > 0
                        spacing: 6

                        QsText {
                            text: "NEARBY DEVICES"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.md3.on_surface_variant
                        }

                        Repeater {
                            model: window.availableDevices
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                width: devCol.width
                                implicitHeight: 52
                                radius: 12
                                color: aMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                                border.color: aMouse.containsMouse ? Colors.md3.outline : Qt.alpha(Colors.md3.outline_variant, 0.5)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    QsText {
                                        text: window.getDeviceIcon(modelData.name)
                                        font.pixelSize: 18
                                        color: Colors.md3.on_surface_variant
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        QsText {
                                            text: modelData.name || modelData.mac
                                            font.pixelSize: 12
                                            color: Colors.md3.on_surface
                                            elide: Text.ElideRight
                                        }
                                        QsText {
                                            text: modelData.mac
                                            font.pixelSize: 10
                                            color: Colors.md3.on_surface_variant
                                        }
                                    }

                                    // Pair Button
                                    Rectangle {
                                        implicitWidth: aPairText.implicitWidth + 14
                                        implicitHeight: 24
                                        radius: 12
                                        color: aPairMouse.containsMouse ? Colors.md3.primary : Colors.md3.surface_container_highest
                                        border.color: Colors.md3.outline_variant
                                        border.width: 1

                                        QsText {
                                            id: aPairText
                                            anchors.centerIn: parent
                                            text: "Pair"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: aPairMouse.containsMouse ? Colors.md3.on_primary : Colors.md3.on_surface
                                        }

                                        MouseArea {
                                            id: aPairMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: window.pairAndConnect(modelData.mac, modelData.name)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: aMouse
                                    anchors.fill: parent
                                    z: -1
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.pairAndConnect(modelData.mac, modelData.name)
                                }
                            }
                        }
                    }
                }
            }

            // Footer Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QsText {
                    readonly property int totalCount: window.connectedDevices.length + window.pairedDevices.length + window.availableDevices.length
                    text: `${totalCount} ${totalCount === 1 ? "device" : "devices"}`
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: btSettRow.implicitWidth + 20
                    implicitHeight: 28
                    radius: 14
                    color: btSettMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                    border.color: Colors.md3.outline_variant
                    border.width: 1

                    RowLayout {
                        id: btSettRow
                        anchors.centerIn: parent
                        spacing: 4
                        QsText { text: "󰒓"; font.pixelSize: 11; color: Colors.md3.primary }
                        QsText {
                            id: btSettText
                            text: "Settings"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.md3.on_surface
                        }
                    }

                    MouseArea {
                        id: btSettMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            window.visible = false
                            if (typeof globalSettingsApp !== "undefined" && globalSettingsApp) {
                                globalSettingsApp.openTab("network")
                            }
                        }
                    }
                }
            }
        }
    }
}
