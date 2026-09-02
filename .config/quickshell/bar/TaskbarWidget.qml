import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland // Native Wayland ToplevelManager
import Quickshell.Widgets
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

Flickable {
    id: root
    implicitHeight: 24
    implicitWidth: contentRow.implicitWidth
    contentWidth: contentRow.implicitWidth
    contentHeight: 24
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    flickableDirection: Flickable.HorizontalFlick

    readonly property bool hasItems: repeater.count > 0
    readonly property int itemCount: repeater.count

    // Wheel scrolling horizontally through windows
    WheelHandler {
        onWheel: (event) => {
            if (root.contentWidth > root.width) {
                root.contentX = Math.max(0, Math.min(root.contentWidth - root.width, root.contentX - event.angleDelta.y))
            }
        }
    }

    RowLayout {
        id: contentRow
        spacing: 2
        height: 24

        Repeater {
            id: repeater
            model: ToplevelManager.toplevels.values

            delegate: MouseArea {
                required property var modelData
                required property int index

                visible: modelData && modelData.appId !== "Alacritty"

                property bool isActive: modelData ? modelData.activated : false
                property bool isHovered: containsMouse

                // Dynamic width: when many apps are open, compress widths smoothly
                implicitWidth: visible ? (20 + (isActive ? (root.itemCount > 4 ? 14 : 24) : (root.itemCount > 4 ? 3 : 6))) : 0
                implicitHeight: visible ? 24 : 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (!modelData) return
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.close()
                    }
                }

                readonly property string appIconName: {
                    if (!modelData) return ""
                    let entry = DesktopEntries.heuristicLookup(modelData.appId)
                    return (entry && entry.icon) ? entry.icon : modelData.appId
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    color: isActive ? Colors.md3.primary : (isHovered ? Colors.md3.secondary : "transparent")

                    Behavior on color { ColorAnimation { duration: 300 } }

                    IconImage {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: Quickshell.iconPath(appIconName, "application-x-executable")
                    }
                }

                Behavior on implicitWidth {
                    NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
