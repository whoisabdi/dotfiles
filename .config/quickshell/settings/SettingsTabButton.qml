import QtQuick
import QtQuick.Layouts
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

Rectangle {
    id: root
    property string title: "Tab"
    property string icon: "󰄛"
    property bool isActive: false

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    radius: 12
    color: isActive ? Colors.md3.primary : "transparent"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Item {
            Layout.preferredWidth: 24; Layout.preferredHeight: 24
            QsText {
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: 18
                color: root.isActive ? Colors.md3.on_primary : Colors.md3.on_surface_variant
            }
        }

        QsText {
            text: root.title
            font.pixelSize: 15
            font.bold: root.isActive
            color: root.isActive ? Colors.md3.on_primary : Colors.md3.on_surface
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
