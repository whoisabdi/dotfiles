import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../globals"
import "../ui"

MouseArea {
    id: root
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton && isReady) {
            sink.audio.muted = !sink.audio.muted
        } else if (mouse.button === Qt.LeftButton) {
            if (typeof globalSettingsApp !== "undefined" && globalSettingsApp) globalSettingsApp.openTab("audio")
        }
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isReady: sink !== null && sink.ready && sink.audio !== null

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // Direct binding to the audio node properties
    property int volume: isReady ? Math.round(sink.audio.volume * 100) : 0
    property bool isMuted: isReady ? sink.audio.muted : false

    function getIcon() {
        if (!isReady || isMuted) return "󰝟";
        if (volume < 33) return "󰕿";
        if (volume < 66) return "󰖀";
        return "󰕾";
    }

    onWheel: (wheel) => {
        if (!isReady) return;
        let step = 0.05;
        // The hardware write is instant; the reactive 'volume' property will automatically update the UI
        if (wheel.angleDelta.y > 0) {
            sink.audio.volume = Math.min(1.0, sink.audio.volume + step);
        } else {
            sink.audio.volume = Math.max(0.0, sink.audio.volume - step);
        }
    }

    RowLayout {
        id: layout
        anchors.fill: parent

        QsText {
            text: getIcon() + " " + root.volume + "%"
            color: isMuted ? Colors.md3.secondary : Colors.md3.on_surface
        }
    }
}
