import QtQuick
import QtQuick.Layouts
import "../globals"

Rectangle {
    id: root

    property int padding: 16
    property bool clickable: false
    readonly property bool isHovered: mouseArea.containsMouse

    signal clicked()

    radius: 16
    color: clickable && isHovered ? Colors.md3.surface_container_high : Colors.md3.surface_container
    border.color: Colors.md3.outline_variant
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
