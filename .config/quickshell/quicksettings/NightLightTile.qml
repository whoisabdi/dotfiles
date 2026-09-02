import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

Rectangle {
    id: root
    Layout.fillWidth: true; Layout.preferredHeight: 62
    radius: 18

    property bool isActive: false

    color: isActive ? Colors.md3.primary_container : Colors.md3.surface_variant
    border.color: isActive ? Colors.md3.primary : Colors.md3.outline_variant
    border.width: 1

    Process {
        id: stateProc
        command: ["sh", "-c", "if pidof hyprsunset >/dev/null 2>&1; then echo 'On'; else echo 'Off'; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.isActive = (text.trim() === "On")
        }
    }

    Process {
        id: toggleProc
        command: ["sh", "-c", "if pidof hyprsunset >/dev/null 2>&1; then killall -9 hyprsunset 2>/dev/null; else setsid hyprsunset -t 4000 >/dev/null 2>&1 & fi"]
        onExited: checkTimer.restart()
    }

    Timer {
        id: checkTimer
        interval: 250
        onTriggered: stateProc.running = true
    }

    onVisibleChanged: if (visible) stateProc.running = true
    Component.onCompleted: stateProc.running = true
    Timer { interval: 3000; running: root.visible; repeat: true; onTriggered: stateProc.running = true }

    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: toggleProc.running = true
    }

    RowLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 8
        Rectangle {
            Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
            color: isActive ? Colors.md3.primary : Colors.md3.surface
            QsText { anchors.centerIn: parent; text: "󰖔"; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 16; color: isActive ? Colors.md3.on_primary : Colors.md3.on_surface }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 1
            QsText { text: "Night Light"; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 12; font.bold: true; color: isActive ? Colors.md3.on_primary_container : Colors.md3.on_surface }
            QsText { text: isActive ? "Active" : "Off"; font.family: "CaskaydiaCove Nerd Font"; font.pixelSize: 10; color: isActive ? Qt.alpha(Colors.md3.on_primary_container, 0.8) : Colors.md3.on_surface_variant }
        }
    }
}
