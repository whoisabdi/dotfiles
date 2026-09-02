import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

MouseArea {
    id: root

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    cursorShape: Qt.PointingHandCursor

    onClicked: {
        globalSettingsApp.openTab("appearance")
    }

    readonly property int brightness: globalBrightnessDaemon ? globalBrightnessDaemon.brightness : 100

    property var icons: ["", "", "", "", "", "", "", "", ""]

    function getIcon() {
        let index = Math.floor((brightness / 100) * (icons.length - 1));
        return icons[Math.max(0, Math.min(icons.length - 1, index))];
    }

    onWheel: (wheel) => {
        if (!globalBrightnessDaemon) return
        let step = wheel.angleDelta.y > 0 ? 5 : -5
        globalBrightnessDaemon.adjust(step)
    }

    RowLayout {
        id: layout
        anchors.fill: parent

        QsText {
            text: getIcon() + " " + root.brightness + "%"
        }
    }
}
