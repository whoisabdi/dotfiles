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
    objectName: "wifipicker"

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "wifipicker"
    exclusiveZone: 0

    color: "transparent"
    visible: false

    property var networks: []
    property var savedConnections: []
    property bool isScanning: false
    property string activePasswordSsid: ""
    property string passwordInput: ""
    property bool showPassword: false
    property string statusMessage: ""
    property bool statusIsError: false

    function toggle() {
        window.visible = !window.visible
        if (window.visible) {
            if (typeof globalBluetoothPicker !== "undefined" && globalBluetoothPicker) {
                globalBluetoothPicker.visible = false
            }
            if (typeof globalQsPanel !== "undefined" && globalQsPanel) {
                globalQsPanel.visible = false
            }
            rescan()
        } else {
            activePasswordSsid = ""
            passwordInput = ""
            statusMessage = ""
        }
    }

    function rescan() {
        if (!globalNetworkDaemon || !globalNetworkDaemon.wifiOn) return
        isScanning = true
        statusMessage = "Scanning networks..."
        statusIsError = false
        scanProcess.running = true
    }

    function connectSaved(ssid) {
        statusMessage = `Connecting to ${ssid}...`
        statusIsError = false
        connectSavedProcess.command = ["nmcli", "connection", "up", "id", ssid]
        connectSavedProcess.running = true
    }

    function connectWithPassword(ssid, pass) {
        if (!pass || pass.length === 0) {
            statusMessage = "Password cannot be empty"
            statusIsError = true
            return
        }
        statusMessage = `Connecting to ${ssid}...`
        statusIsError = false
        connectPassProcess.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", pass]
        connectPassProcess.running = true
    }

    function disconnectWifi() {
        statusMessage = "Disconnecting..."
        statusIsError = false
        disconnectProcess.running = true
    }

    function forgetNetwork(ssid) {
        statusMessage = `Forgetting ${ssid}...`
        statusIsError = false
        forgetProcess.command = ["nmcli", "connection", "delete", "id", ssid]
        forgetProcess.running = true
    }

    IpcHandler {
        target: "wifipicker"
        function toggle(): void { window.toggle() }
        function show(): void {
            if (typeof globalBluetoothPicker !== "undefined" && globalBluetoothPicker) {
                globalBluetoothPicker.visible = false
            }
            if (typeof globalQsPanel !== "undefined" && globalQsPanel) {
                globalQsPanel.visible = false
            }
            window.visible = true
            window.rescan()
        }
        function hide(): void { window.visible = false }
    }

    // Process to scan Wi-Fi and fetch saved connections
    Process {
        id: scanProcess
        command: ["sh", "-c", "
            nmcli dev wifi rescan 2>/dev/null;
            SAVED=$(nmcli -t -f NAME,TYPE connection show | grep ':802-11-wireless' | cut -d: -f1);
            WIFI_LIST=$(nmcli -t -f in-use,signal,security,ssid dev wifi list 2>/dev/null);
            echo \"===SAVED===\";
            echo \"$SAVED\";
            echo \"===NETWORKS===\";
            echo \"$WIFI_LIST\";
        "]
        stdout: StdioCollector {
            onStreamFinished: {
                window.isScanning = false
                let textContent = text.replace(/\r/g, "")
                let parts = textContent.split("===NETWORKS===")
                let savedPart = parts[0].replace("===SAVED===", "").trim()
                let networksPart = (parts.length > 1) ? parts[1].trim() : ""

                let savedList = savedPart.split("\n").map(s => s.trim()).filter(s => s.length > 0)
                window.savedConnections = savedList

                let lines = networksPart.split("\n")
                let seenSsids = new Set()
                let parsed = []

                for (let line of lines) {
                    if (!line || line.trim().length === 0) continue
                    let fields = line.split(":")
                    if (fields.length < 4) continue
                    let inUse = fields[0].trim() === "*"
                    let signal = parseInt(fields[1]) || 0
                    let security = fields[2].trim()
                    let ssid = fields.slice(3).join(":").trim()

                    if (ssid.length === 0 || ssid === "--") continue
                    if (seenSsids.has(ssid) && !inUse) continue

                    seenSsids.add(ssid)
                    parsed.push({
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        isSecured: security.length > 0 && security !== "--",
                        isConnected: inUse,
                        isSaved: savedList.includes(ssid)
                    })
                }

                // Sort: Connected first, then Saved, then by signal strength descending
                parsed.sort((a, b) => {
                    if (a.isConnected !== b.isConnected) return a.isConnected ? -1 : 1
                    if (a.isSaved !== b.isSaved) return a.isSaved ? -1 : 1
                    return b.signal - a.signal
                })

                window.networks = parsed
                if (window.statusMessage === "Scanning networks...") {
                    window.statusMessage = ""
                }
                if (globalNetworkDaemon) globalNetworkDaemon.refresh()
            }
        }
    }

    Process {
        id: connectSavedProcess
        stdout: StdioCollector {
            onStreamFinished: {
                window.statusMessage = "Connected successfully!"
                window.statusIsError = false
                window.rescan()
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
        id: connectPassProcess
        stdout: StdioCollector {
            onStreamFinished: {
                window.statusMessage = "Connected successfully!"
                window.statusIsError = false
                window.activePasswordSsid = ""
                window.passwordInput = ""
                window.rescan()
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
        command: ["sh", "-c", "nmcli dev disconnect $(nmcli -t -f DEVICE,TYPE dev | grep ':wifi' | cut -d: -f1 | head -n 1)"]
        onExited: {
            window.statusMessage = "Disconnected"
            window.statusIsError = false
            window.rescan()
        }
    }

    Process {
        id: forgetProcess
        onExited: {
            window.statusMessage = "Network forgotten"
            window.statusIsError = false
            window.rescan()
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
                    color: globalNetworkDaemon && globalNetworkDaemon.wifiOn ? Colors.md3.primary_container : Colors.md3.surface_container
                    border.color: globalNetworkDaemon && globalNetworkDaemon.wifiOn ? Colors.md3.primary : Colors.md3.outline_variant
                    border.width: 1

                    QsText {
                        anchors.centerIn: parent
                        text: globalNetworkDaemon ? globalNetworkDaemon.getWifiIcon() : "󰤨"
                        font.pixelSize: 18
                        color: globalNetworkDaemon && globalNetworkDaemon.wifiOn ? Colors.md3.primary : Colors.md3.on_surface_variant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    QsText {
                        text: "Wi-Fi Networks"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.md3.on_surface
                    }

                    QsText {
                        text: (globalNetworkDaemon && globalNetworkDaemon.wifiOn)
                            ? (globalNetworkDaemon.currentSsid !== "Disconnected" ? globalNetworkDaemon.currentSsid : "Available Networks")
                            : "Wi-Fi is Disabled"
                        font.pixelSize: 11
                        color: (globalNetworkDaemon && globalNetworkDaemon.currentSsid !== "Disconnected") ? Colors.md3.primary : Colors.md3.on_surface_variant
                        elide: Text.ElideRight
                    }
                }

                // Rescan Button
                Rectangle {
                    visible: globalNetworkDaemon && globalNetworkDaemon.wifiOn
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: rescanMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
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
                        id: rescanMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: window.rescan()
                    }
                }

                // Wi-Fi Master Toggle Switch
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 24
                    radius: 12
                    color: (globalNetworkDaemon && globalNetworkDaemon.wifiOn) ? Colors.md3.primary : Colors.md3.surface_variant
                    border.color: (globalNetworkDaemon && globalNetworkDaemon.wifiOn) ? Colors.md3.primary : Colors.md3.outline_variant
                    border.width: 1

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: (globalNetworkDaemon && globalNetworkDaemon.wifiOn) ? Colors.md3.on_primary : Colors.md3.outline
                        anchors.verticalCenter: parent.verticalCenter
                        x: (globalNetworkDaemon && globalNetworkDaemon.wifiOn) ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (globalNetworkDaemon) {
                                globalNetworkDaemon.toggleWifi()
                                scanTimer.restart()
                            }
                        }
                    }
                }
            }

            Timer {
                id: scanTimer
                interval: 800
                onTriggered: window.rescan()
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

            // Network List
            ListView {
                id: netList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Math.min(320, window.networks.length * 56)
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: (globalNetworkDaemon && globalNetworkDaemon.wifiOn) ? window.networks : []

                QsText {
                    anchors.centerIn: parent
                    visible: (!globalNetworkDaemon || !globalNetworkDaemon.wifiOn)
                    text: "Turn on Wi-Fi to see available networks"
                    font.pixelSize: 12
                    font.italic: true
                    color: Colors.md3.on_surface_variant
                }

                delegate: Rectangle {
                    id: netItem
                    required property var modelData
                    required property int index

                    width: netList.width
                    implicitHeight: isPasswordOpen ? (cardRow.implicitHeight + passwordBox.implicitHeight + 20) : (cardRow.implicitHeight + 14)
                    radius: 12
                    color: modelData.isConnected
                        ? Qt.alpha(Colors.md3.primary_container, 0.45)
                        : (itemMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container)
                    border.color: modelData.isConnected
                        ? Colors.md3.primary
                        : (itemMouse.containsMouse ? Colors.md3.outline : Qt.alpha(Colors.md3.outline_variant, 0.5))
                    border.width: modelData.isConnected ? 1.5 : 1

                    readonly property bool isPasswordOpen: window.activePasswordSsid === modelData.ssid

                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        id: itemCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        // Main Row
                        RowLayout {
                            id: cardRow
                            Layout.fillWidth: true
                            spacing: 10

                            // Signal Icon
                            QsText {
                                text: {
                                    if (modelData.signal >= 75) return "󰤨";
                                    if (modelData.signal >= 50) return "󰤥";
                                    if (modelData.signal >= 25) return "󰤢";
                                    return "󰤟";
                                }
                                font.pixelSize: 18
                                color: modelData.isConnected ? Colors.md3.primary : Colors.md3.on_surface
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                RowLayout {
                                    spacing: 6
                                    QsText {
                                        text: modelData.ssid
                                        font.pixelSize: 12
                                        font.bold: modelData.isConnected || modelData.isSaved
                                        color: modelData.isConnected ? Colors.md3.primary : Colors.md3.on_surface
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 170
                                    }

                                    QsText {
                                        visible: modelData.isSecured
                                        text: "󰌾"
                                        font.pixelSize: 11
                                        color: Colors.md3.on_surface_variant
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    QsText {
                                        text: modelData.isConnected ? "Connected" : (modelData.isSaved ? "Saved" : `${modelData.signal}%`)
                                        font.pixelSize: 10
                                        color: modelData.isConnected ? Colors.md3.primary : Colors.md3.on_surface_variant
                                    }
                                }
                            }

                            // 1. Disconnect Action (if connected)
                            Rectangle {
                                visible: modelData.isConnected
                                implicitWidth: discText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 12
                                color: discMouse.containsMouse ? Colors.md3.error : Qt.alpha(Colors.md3.error_container, 0.6)
                                border.color: Colors.md3.error
                                border.width: 1

                                QsText {
                                    id: discText
                                    anchors.centerIn: parent
                                    text: "Disconnect"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: discMouse.containsMouse ? Colors.md3.on_error : Colors.md3.error
                                }

                                MouseArea {
                                    id: discMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: window.disconnectWifi()
                                }
                            }

                            // 2. Saved Network Actions
                            RowLayout {
                                visible: !modelData.isConnected && modelData.isSaved
                                spacing: 4

                                Rectangle {
                                    implicitWidth: connSavedText.implicitWidth + 14
                                    implicitHeight: 24
                                    radius: 12
                                    color: connSavedMouse.containsMouse ? Colors.md3.primary : Colors.md3.primary_container

                                    QsText {
                                        id: connSavedText
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: connSavedMouse.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container
                                    }

                                    MouseArea {
                                        id: connSavedMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: window.connectSaved(modelData.ssid)
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    radius: 12
                                    color: forgetMouse.containsMouse ? Colors.md3.error_container : "transparent"

                                    QsText {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.pixelSize: 12
                                        color: forgetMouse.containsMouse ? Colors.md3.error : Colors.md3.on_surface_variant
                                    }

                                    MouseArea {
                                        id: forgetMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: window.forgetNetwork(modelData.ssid)
                                    }
                                }
                            }

                            // 3. New Network Join Button
                            Rectangle {
                                visible: !modelData.isConnected && !modelData.isSaved
                                implicitWidth: connText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 12
                                color: connMouse.containsMouse ? Colors.md3.primary : Colors.md3.surface_container_highest
                                border.color: Colors.md3.outline_variant
                                border.width: 1

                                QsText {
                                    id: connText
                                    anchors.centerIn: parent
                                    text: "Join"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: connMouse.containsMouse ? Colors.md3.on_primary : Colors.md3.on_surface
                                }

                                MouseArea {
                                    id: connMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (modelData.isSecured) {
                                            if (window.activePasswordSsid === modelData.ssid) {
                                                window.activePasswordSsid = ""
                                            } else {
                                                window.activePasswordSsid = modelData.ssid
                                                window.passwordInput = ""
                                            }
                                        } else {
                                            window.connectSaved(modelData.ssid)
                                        }
                                    }
                                }
                            }
                        }

                        // Inline Password Form
                        Rectangle {
                            id: passwordBox
                            visible: netItem.isPasswordOpen
                            Layout.fillWidth: true
                            implicitHeight: visible ? 42 : 0
                            radius: 8
                            color: Colors.md3.surface_container_highest
                            border.color: Colors.md3.primary
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                TextField {
                                    id: passField
                                    Layout.fillWidth: true
                                    placeholderText: "Password..."
                                    placeholderTextColor: Colors.md3.outline
                                    color: Colors.md3.on_surface
                                    font.pixelSize: 11
                                    echoMode: window.showPassword ? TextInput.Normal : TextInput.Password
                                    background: Item {}
                                    text: window.passwordInput
                                    onTextChanged: window.passwordInput = text
                                    onAccepted: window.connectWithPassword(modelData.ssid, text)
                                    Keys.onEscapePressed: (event) => { window.visible = false; event.accepted = true; }
                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Escape) {
                                            window.visible = false
                                            event.accepted = true
                                        }
                                    }
                                }

                                MouseArea {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.showPassword = !window.showPassword
                                    QsText {
                                        anchors.centerIn: parent
                                        text: window.showPassword ? "󰈈" : "󰈉"
                                        font.pixelSize: 13
                                        color: Colors.md3.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 30
                                    implicitHeight: 26
                                    radius: 6
                                    color: Colors.md3.primary

                                    QsText {
                                        anchors.centerIn: parent
                                        text: "󰁕"
                                        font.pixelSize: 13
                                        color: Colors.md3.on_primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.connectWithPassword(modelData.ssid, passField.text)
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 6
                                    color: Colors.md3.surface_container

                                    QsText {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.pixelSize: 12
                                        color: Colors.md3.on_surface_variant
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.activePasswordSsid = ""
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.isConnected) return
                            if (modelData.isSaved) {
                                window.connectSaved(modelData.ssid)
                            } else if (modelData.isSecured) {
                                if (window.activePasswordSsid === modelData.ssid) {
                                    window.activePasswordSsid = ""
                                } else {
                                    window.activePasswordSsid = modelData.ssid
                                    window.passwordInput = ""
                                }
                            } else {
                                window.connectSaved(modelData.ssid)
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
                    text: `${window.networks.length} ${window.networks.length === 1 ? "network" : "networks"} found`
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: settRow.implicitWidth + 20
                    implicitHeight: 28
                    radius: 14
                    color: settMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                    border.color: Colors.md3.outline_variant
                    border.width: 1

                    RowLayout {
                        id: settRow
                        anchors.centerIn: parent
                        spacing: 4
                        QsText { text: "󰒓"; font.pixelSize: 11; color: Colors.md3.primary }
                        QsText {
                            id: settText
                            text: "Settings"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.md3.on_surface
                        }
                    }

                    MouseArea {
                        id: settMouse
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
