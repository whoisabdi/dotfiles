import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland // Native Hyprland integration
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

RowLayout {
    id: root
    spacing: 4

    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    Repeater {
        model: 10 // Fixed workspace slots 1-10

        delegate: Rectangle {
            id: wsRect
            required property int index
            readonly property int wsId: index + 1

            readonly property var wsObj: {
                for (let ws of Hyprland.workspaces.values) {
                    if (ws && ws.id === wsId && !ws.name.startsWith("special")) return ws;
                }
                return null;
            }

            readonly property bool isActive: wsId === root.focusedId
            readonly property bool isOccupied: wsObj !== null
            readonly property bool shouldDisplay: isOccupied || isActive
            readonly property bool isHovered: mouseArea.containsMouse

            visible: implicitWidth > 0
            implicitWidth: shouldDisplay ? (textLabel.implicitWidth + (isActive ? 24 : 8)) : 0
            implicitHeight: shouldDisplay ? 20 : 0
            radius: 9
            clip: true

            color: isActive ? Colors.md3.primary : (isHovered ? Qt.alpha(Colors.md3.secondary, 0.85) : Qt.alpha(Colors.md3.surface_variant, 0.60))

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutBack
                }
            }

            Behavior on color {
                ColorAnimation { duration: 250 }
            }

            QsText {
                id: textLabel
                anchors.centerIn: parent
                text: wsId.toString()
                font.pixelSize: 11
                font.bold: isActive
                opacity: wsRect.shouldDisplay ? 1.0 : 0.0
                color: isActive ? Colors.md3.on_primary : (isHovered ? Colors.md3.on_secondary : Colors.md3.on_surface)
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (wsObj && typeof wsObj.activate === "function") {
                        wsObj.activate();
                    } else if (typeof Hyprland.dispatch === "function") {
                        Hyprland.dispatch("workspace " + wsId);
                    }
                }
            }
        }
    }
}
