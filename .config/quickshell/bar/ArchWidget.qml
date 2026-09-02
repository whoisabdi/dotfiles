import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../globals"
import "../ui"

MouseArea {
    id: root
    implicitWidth: 36
    implicitHeight: 36
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
        if (typeof globalQsPanel !== "undefined" && globalQsPanel) {
            globalQsPanel.toggle()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: root.containsMouse ? Qt.alpha(Colors.md3.surface_container_high, 0.85) : Qt.alpha(Colors.md3.surface_container, 0.70)
        border.color: root.containsMouse ? Colors.md3.primary : Qt.alpha(Colors.md3.outline_variant, 0.5)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        QsText {
            anchors.centerIn: parent
            text: "󰣇"
            font.pixelSize: 18
            color: Colors.md3.primary
            scale: root.pressed ? 0.88 : (root.containsMouse ? 1.15 : 1.0)
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        }
    }
}
