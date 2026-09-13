import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../globals"
import "../osd"
import "../quicksettings"

PanelWindow {
    id: window
    WlrLayershell.namespace: "qspanel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: false

    function toggle() {
        visible = !visible
        if (visible) {
            if (typeof globalWifiPicker !== "undefined" && globalWifiPicker) globalWifiPicker.visible = false
            if (typeof globalBluetoothPicker !== "undefined" && globalBluetoothPicker) globalBluetoothPicker.visible = false
            uptimeProc.running = true
            bgMouse.forceActiveFocus()
        }
    }

    readonly property var activeHistory: globalNotifications ? globalNotifications.historyNotifications : []
    property string uptimeStr: "Up..."

    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p | sed 's/up //g'"]
        stdout: StdioCollector {
            onStreamFinished: window.uptimeStr = text.trim()
        }
    }

    IpcHandler {
        target: "qspanel"
        function toggle(): void { window.toggle() }
        function show(): void {
            if (typeof globalWifiPicker !== "undefined" && globalWifiPicker) globalWifiPicker.visible = false
            if (typeof globalBluetoothPicker !== "undefined" && globalBluetoothPicker) globalBluetoothPicker.visible = false
            window.visible = true
            uptimeProc.running = true
            bgMouse.forceActiveFocus()
        }
        function hide(): void { window.visible = false }
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
        width: 380
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 12
        radius: 20
        color: Colors.md3.surface_container_high
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
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // 1. Header Bar: Profile & Quick System Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    width: 40; height: 40

                    // Fallback container
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: Colors.md3.primary_container
                        QsText {
                            anchors.centerIn: parent
                            text: "󰣇"
                            font.pixelSize: 20
                            color: Colors.md3.on_primary_container
                        }
                    }

                    // Circular Avatar Canvas
                    Canvas {
                        id: avatarCanvas
                        anchors.fill: parent
                        readonly property string facePath: "file://" + Quickshell.env("HOME") + "/.face"

                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.beginPath();
                            ctx.arc(20, 20, 20, 0, Math.PI * 2, true);
                            ctx.closePath();
                            ctx.clip();
                            ctx.drawImage(facePath, 0, 0, 40, 40);
                        }

                        Component.onCompleted: loadImage(facePath)
                        onImageLoaded: requestPaint()
                    }
                }

                ColumnLayout {
                    spacing: 0
                    QsText {
                        text: Quickshell.env("USER") ? Quickshell.env("USER").toUpperCase() : "USER"
                        font.bold: true
                        font.pixelSize: 13
                        color: Colors.md3.on_surface
                    }
                    QsText {
                        text: "󱑂 " + window.uptimeStr
                        font.pixelSize: 10
                        color: Colors.md3.on_surface_variant
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Action Buttons
                RowLayout {
                    spacing: 8

                    // Settings
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: Colors.md3.surface_container
                        border.color: Colors.md3.outline_variant; border.width: 1
                        QsText { anchors.centerIn: parent; text: "󰒓"; font.pixelSize: 14; color: Colors.md3.on_surface }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.visible = false
                                if (globalSettingsApp) globalSettingsApp.openTab("appearance")
                            }
                        }
                    }

                    // Power
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: Colors.md3.error_container
                        QsText { anchors.centerIn: parent; text: "󰐥"; font.pixelSize: 14; color: Colors.md3.on_error_container }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.visible = false
                                if (globalPowermenu) globalPowermenu.toggle()
                            }
                        }
                    }
                }
            }

            // 2. Quick Settings 2x2 Grid
            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                NightLightTile {}
                CaffeineTile {}
                DndTile {}
                GameModeTile {}
            }

            // 3. Dual Hardware Sliders (Volume & Brightness)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                VolumeSliderCard {}
                BrightnessSliderCard {}
            }

            // 4. Notifications Section
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                QsText {
                    text: "Notifications" + (window.activeHistory.length > 0 ? ` (${window.activeHistory.length})` : "")
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.md3.primary
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: window.activeHistory.length > 0
                    implicitWidth: clearText.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: Colors.md3.surface_variant

                    QsText {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.pixelSize: 10
                        font.bold: true
                        color: Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (globalNotifications) globalNotifications.dismissAll()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: notifList
                    anchors.fill: parent
                    spacing: 8
                    clip: true
                    model: window.activeHistory

                    delegate: Rectangle {
                        id: cardDelegate
                        width: ListView.view.width
                        height: 64
                        radius: 12
                        color: cardMouse.containsMouse ? Colors.md3.surface_container_high : Colors.md3.surface_container
                        border.color: cardMouse.containsMouse ? Colors.md3.outline : Colors.md3.outline_variant
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.actions && modelData.actions.length > 0) {
                                    try {
                                        let act = modelData.actions.find(a => a.id === "default") || modelData.actions[0];
                                        if (act) modelData.invokeAction(act.id);
                                    } catch (e) {}
                                }
                                if (globalNotifications) globalNotifications.dismissNotification(modelData);
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 8; color: Colors.md3.surface_variant
                                clip: true
                                IconImage {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    source: (modelData.appIcon && modelData.appIcon.length > 0)
                                        ? modelData.appIcon
                                        : Quickshell.iconPath(modelData.appName || "dialog-information", "application-x-executable")
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                QsText { text: modelData.summary || ""; font.pixelSize: 12; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                                QsText { text: modelData.body || ""; font.pixelSize: 11; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                            }

                            MouseArea {
                                implicitWidth: 24; implicitHeight: 24; cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: if (globalNotifications) globalNotifications.dismissNotification(modelData)
                                QsText { anchors.centerIn: parent; text: "󰅖"; font.pixelSize: 14; color: parent.containsMouse ? Colors.md3.error : Qt.alpha(Colors.md3.error, 0.7) }
                            }
                        }
                    }
                }

                QsText {
                    anchors.centerIn: parent
                    visible: !window.activeHistory || window.activeHistory.length === 0
                    text: "No notifications"
                    font.pixelSize: 12
                    font.italic: true
                    color: Colors.md3.on_surface_variant
                }
            }
        }
    }
}
