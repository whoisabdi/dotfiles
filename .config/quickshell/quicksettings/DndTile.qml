import QtQuick
import QtQuick.Layouts
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

Rectangle {
    id: root
    Layout.fillWidth: true; Layout.preferredHeight: 62
    radius: 18

    readonly property bool isActive: (typeof globalNotifications !== "undefined" && globalNotifications) ? globalNotifications.dndEnabled : false

    color: isActive ? Colors.md3.primary_container : Colors.md3.surface_variant
    border.color: isActive ? Colors.md3.primary : Colors.md3.outline_variant
    border.width: 1

    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (typeof globalNotifications !== "undefined" && globalNotifications) {
                globalNotifications.dndEnabled = !globalNotifications.dndEnabled;
                if (globalNotifications.dndEnabled) {
                    globalNotifications.popupNotifications = [];
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 8
        Rectangle {
            Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
            color: isActive ? Colors.md3.primary : Colors.md3.surface
            QsText {
                anchors.centerIn: parent
                text: isActive ? "󰂛" : "󰂚"
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 16
                color: isActive ? Colors.md3.on_primary : Colors.md3.on_surface
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 1
            QsText {
                text: "Do Not Disturb"
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 12
                font.bold: true
                color: isActive ? Colors.md3.on_primary_container : Colors.md3.on_surface
            }
            QsText {
                text: isActive ? "Silent" : "Off"
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 10
                color: isActive ? Qt.alpha(Colors.md3.on_primary_container, 0.8) : Colors.md3.on_surface_variant
            }
        }
    }
}
