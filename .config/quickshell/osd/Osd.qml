import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

PanelWindow {
    id: window
    objectName: "osd"

    anchors {
        bottom: true
    }

    margins {
        bottom: 120
    }

    implicitWidth: 320
    implicitHeight: 48
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "osd"

    color: "transparent"
    visible: false

    property string osdIcon: "󰕾"
    property real osdValue: 0
    property bool isMuted: false

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: window.visible = false
    }

    function showOsd(icon, value, muted) {
        osdIcon = icon
        osdValue = Math.max(0.0, Math.min(1.0, value))
        isMuted = muted
        window.visible = true
        hideTimer.restart()
    }

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [window.sink, window.source].filter(Boolean)
    }

    IpcHandler {
        target: "osd"

        function volUp(): void {
            if (sink && sink.audio) {
                sink.audio.volume = Math.min(sink.audio.volume + 0.05, 1.0)
                sink.audio.muted = false
            }
            let v = sink?.audio?.volume ?? 0
            let m = sink?.audio?.muted ?? false
            showOsd(v > 0.5 ? "󰕾" : "󰖀", v, m)
        }
        function volDown(): void {
            if (sink && sink.audio) {
                sink.audio.volume = Math.max(sink.audio.volume - 0.05, 0.0)
            }
            let v = sink?.audio?.volume ?? 0
            let m = sink?.audio?.muted ?? false
            showOsd(v > 0 ? "󰖀" : "󰝟", v, m)
        }
        function volMute(): void {
            if (sink && sink.audio) {
                sink.audio.muted = !sink.audio.muted
            }
            let v = sink?.audio?.volume ?? 0
            let m = sink?.audio?.muted ?? false
            showOsd(m ? "󰝟" : "󰕾", v, m)
        }
        function micMute(): void {
            if (source && source.audio) {
                source.audio.muted = !source.audio.muted
            }
            let m = source?.audio?.muted ?? false
            showOsd(m ? "󰍭" : "󰍬", source?.audio?.volume ?? 0, m)
        }
        function brightUp(): void {
            if (globalBrightnessDaemon) {
                globalBrightnessDaemon.adjust(5)
                showOsd("󰃠", (globalBrightnessDaemon.brightness + 5) / 100.0, false)
            }
        }
        function brightDown(): void {
            if (globalBrightnessDaemon) {
                globalBrightnessDaemon.adjust(-5)
                showOsd("󰃠", (globalBrightnessDaemon.brightness - 5) / 100.0, false)
            }
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: 20
        color: Qt.alpha(Colors.md3.surface_container_low, 0.4)
        border.color: Colors.md3.outline
        border.width: 2

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            QsText {
                text: osdIcon
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 18
                color: Colors.md3.primary
                opacity: isMuted ? 0.5 : 1.0
            }

            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 999
                color: Qt.alpha(Colors.md3.primary_container, 0.5)

                Rectangle {
                    width: parent.width * osdValue
                    height: parent.height
                    radius: 999
                    color: isMuted ? Colors.md3.outline : Colors.md3.primary
                    opacity: isMuted ? 0.5 : 1.0

                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }
            }

            QsText {
                text: Math.round(osdValue * 100) + "%"
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: Colors.md3.primary
                opacity: isMuted ? 0.5 : 1.0
            }
        }
    }
}
