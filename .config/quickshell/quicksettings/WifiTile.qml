import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

Rectangle {
    id: root
    Layout.fillWidth: true; Layout.preferredHeight: 62
    radius: 18

    readonly property bool isConnected: globalNetworkDaemon ? globalNetworkDaemon.wifiOn : false
    readonly property string status: globalNetworkDaemon ? globalNetworkDaemon.currentSsid : "Disconnected"

    color: isConnected ? Colors.md3.primary_container : Colors.md3.surface_variant
    border.color: isConnected ? Colors.md3.primary : Colors.md3.outline_variant
    border.width: 1

    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: if (globalNetworkDaemon) globalNetworkDaemon.toggleWifi()
    }

    RowLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 8
        Rectangle {
            Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
            color: isConnected ? Colors.md3.primary : Colors.md3.surface
            QsText {
                anchors.centerIn: parent
                text: globalNetworkDaemon ? globalNetworkDaemon.getWifiIcon() : "󰤭"
                font.pixelSize: 18
                color: isConnected ? Colors.md3.on_primary : Colors.md3.on_surface
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 1
            QsText { text: "Wi-Fi"; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 12; font.bold: true; color: isConnected ? Colors.md3.on_primary_container : Colors.md3.on_surface }
            QsText { text: root.status; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 10; color: isConnected ? Qt.alpha(Colors.md3.on_primary_container, 0.8) : Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }
}
