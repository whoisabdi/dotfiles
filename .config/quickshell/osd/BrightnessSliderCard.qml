import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../globals"
import "../ui"

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 52
    radius: 14
    color: Colors.md3.surface_variant

    property int brightnessLevel: globalBrightnessDaemon ? globalBrightnessDaemon.brightness : 50
    property bool isDragging: mouseArea.pressed

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            QsText { text: "Brightness"; font.pixelSize: 11; font.bold: true; color: Colors.md3.on_surface_variant }
            Item { Layout.fillWidth: true }
            QsText { text: root.brightnessLevel + "%"; font.pixelSize: 11; font.bold: true; color: Colors.md3.primary }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            QsText {
                text: "󰃠"
                font.pixelSize: 16
                color: Colors.md3.primary
            }

            Rectangle {
                id: brightTrack
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                border.color: Qt.alpha(Colors.md3.outline_variant, 0.6)
                border.width: 1

                Rectangle {
                    width: brightTrack.width * (Math.max(0, Math.min(100, root.brightnessLevel)) / 100)
                    height: parent.height
                    radius: 4
                    color: Colors.md3.primary

                    Behavior on width {
                        enabled: !root.isDragging
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor

                    onPressed: (mouse) => updateBright(mouse.x)
                    onPositionChanged: (mouse) => updateBright(mouse.x)

                    function updateBright(mx) {
                        let ratio = Math.max(0.05, Math.min(1.0, mx / brightTrack.width))
                        let val = Math.round(ratio * 100)
                        root.brightnessLevel = val
                        if (globalBrightnessDaemon) {
                            globalBrightnessDaemon.setBrightness(val)
                        }
                    }
                }
            }
        }
    }
}
