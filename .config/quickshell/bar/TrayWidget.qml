import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../globals"
import "../ui"

Rectangle {
    id: trayRoot
    visible: SystemTray.items.values.length > 0
    implicitWidth: trayLayout.implicitWidth + 24
    implicitHeight: 36
    radius: 18
    color: Qt.alpha(Colors.md3.surface_container, 0.70)
    border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
    border.width: 1

    RowLayout {
        id: trayLayout
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: SystemTray.items.values
            delegate: MouseArea {
                id: trayItemArea
                required property var modelData
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                width: 22
                height: 22
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData.menu
                    anchor.item: trayItemArea
                }

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu && menuAnchor.menu) {
                            menuAnchor.open()
                        } else if (typeof modelData.contextMenu === "function") {
                            modelData.contextMenu(mouse.x, mouse.y)
                        } else if (typeof modelData.secondaryActivate === "function") {
                            modelData.secondaryActivate()
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        if (typeof modelData.secondaryActivate === "function") {
                            modelData.secondaryActivate()
                        }
                    } else {
                        if (typeof modelData.activate === "function") {
                            modelData.activate()
                        }
                    }
                }

                Image {
                    anchors.fill: parent
                    source: modelData.icon || ""
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
    }
}
