import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../globals"
import "../ui"

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 52
    radius: 14
    color: Colors.md3.surface_variant

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isReady: sink !== null && sink.ready && sink.audio !== null

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    property int volumeLevel: isReady ? Math.round(sink.audio.volume * 100) : 0
    property bool isMuted: isReady ? sink.audio.muted : false

    function getIcon() {
        if (!isReady || isMuted) return "󰝟";
        if (volumeLevel < 33) return "󰕿";
        if (volumeLevel < 66) return "󰖀";
        return "󰕾";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            QsText { text: "Volume"; font.pixelSize: 11; font.bold: true; color: Colors.md3.on_surface_variant }
            Item { Layout.fillWidth: true }
            QsText { 
                text: root.isMuted ? "Muted" : root.volumeLevel + "%"
                font.pixelSize: 11
                font.bold: true
                color: root.isMuted ? Colors.md3.error : Colors.md3.primary 
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MouseArea {
                implicitWidth: 20
                implicitHeight: 20
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (isReady) sink.audio.muted = !sink.audio.muted
                }

                QsText {
                    anchors.centerIn: parent
                    text: root.getIcon()
                    font.pixelSize: 16
                    color: root.isMuted ? Colors.md3.error : Colors.md3.primary
                }
            }

            Rectangle {
                id: volTrack
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                border.color: Qt.alpha(Colors.md3.outline_variant, 0.6)
                border.width: 1

                Rectangle {
                    width: volTrack.width * (root.isMuted ? 0 : Math.max(0, Math.min(100, root.volumeLevel)) / 100)
                    height: parent.height
                    radius: 4
                    color: root.isMuted ? Colors.md3.outline : Colors.md3.primary

                    Behavior on width {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor

                    onPressed: (mouse) => updateVol(mouse.x)
                    onPositionChanged: (mouse) => updateVol(mouse.x)

                    function updateVol(mx) {
                        if (!isReady) return;
                        let ratio = Math.max(0, Math.min(1, mx / volTrack.width))
                        sink.audio.muted = false
                        sink.audio.volume = ratio
                    }
                }
            }
        }
    }
}
