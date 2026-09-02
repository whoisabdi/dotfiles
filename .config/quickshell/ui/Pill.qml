import QtQuick
import QtQuick.Layouts
import "../globals"

Rectangle {
    id: root

    property bool clickable: false
    property bool active: false
    property int paddingHorizontal: 12
    property int spacing: 8
    readonly property bool isHovered: mouseArea.containsMouse

    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal middleClicked(var mouse)
    signal wheelScrolled(var wheel)

    implicitHeight: 36
    implicitWidth: layout.implicitWidth + (paddingHorizontal * 2)
    radius: height / 2

    color: active 
           ? Colors.md3.primary 
           : (clickable && isHovered ? Qt.alpha(Colors.md3.surface_container_high, 0.85) : Qt.alpha(Colors.md3.surface_container, 0.70))
    border.color: active ? Colors.md3.primary : Qt.alpha(Colors.md3.outline_variant, 0.5)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) root.clicked(mouse)
            else if (mouse.button === Qt.RightButton) root.rightClicked(mouse)
            else if (mouse.button === Qt.MiddleButton) root.middleClicked(mouse)
        }

        onWheel: (wheel) => root.wheelScrolled(wheel)
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: root.spacing
    }

    default property alias content: layout.data
}
