import QtQuick
import QtQuick.Layouts
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

RowLayout {
    property bool altFormat: false
    readonly property var currentTime: Config.currentTime

    QsText {
        text: altFormat
              ? Qt.formatDateTime(currentTime, "HH:mm") + " 󰃭 " + Qt.formatDateTime(currentTime, "dd·MM·yy")
              : Qt.formatDateTime(currentTime, "hh:mm AP")

        MouseArea {
            anchors.fill: parent
            onClicked: altFormat = !altFormat
            cursorShape: Qt.PointingHandCursor
        }
    }
}
