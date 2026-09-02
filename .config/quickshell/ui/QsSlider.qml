import QtQuick
import QtQuick.Layouts
import "../globals"

Rectangle {
    id: root

    property string title: ""
    property string icon: ""
    property real value: 0.5
    property bool isMuted: false
    readonly property bool isDragging: mouseArea.pressed

    signal moved(real val)
    signal iconClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 52
    radius: 14
    color: Colors.md3.surface_container

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            QsText {
                visible: root.title !== ""
                text: root.title
                font.pixelSize: 11
                font.bold: true
                color: Colors.md3.on_surface_variant
            }

            Item { Layout.fillWidth: true }

            QsText {
                text: root.isMuted ? "Muted" : Math.round(root.value * 100) + "%"
                font.pixelSize: 11
                font.bold: true
                color: root.isMuted ? Colors.md3.error : Colors.md3.primary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MouseArea {
                implicitWidth: 24
                implicitHeight: 24
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()

                QsText {
                    anchors.centerIn: parent
                    text: root.icon
                    font.pixelSize: 16
                    color: root.isMuted ? Colors.md3.error : Colors.md3.primary
                }
            }

            Rectangle {
                id: track
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Qt.alpha(Colors.md3.outline_variant, 0.4)

                Rectangle {
                    width: track.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    radius: 4
                    color: root.isMuted ? Colors.md3.outline : Colors.md3.primary

                    Behavior on width {
                        enabled: !root.isDragging
                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor

                    onPressed: (mouse) => updateVal(mouse.x)
                    onPositionChanged: (mouse) => updateVal(mouse.x)

                    function updateVal(mx) {
                        let ratio = Math.max(0.0, Math.min(1.0, mx / track.width))
                        root.value = ratio
                        root.moved(ratio)
                    }
                }
            }
        }
    }
}
