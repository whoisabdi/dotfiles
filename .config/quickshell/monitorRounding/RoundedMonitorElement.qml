import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var screen

    property int cornerSize: 16
    property color cornerColor: "#000000"

    WlrLayershell.namespace: "monitor-rounding"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    mask: Region {}

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 0
        fillColor: root.cornerColor
        anchors.left: parent.left
        anchors.top: parent.top
    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 1
        fillColor: root.cornerColor
        anchors.right: parent.right
        anchors.top: parent.top
    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 2
        fillColor: root.cornerColor
        anchors.left: parent.left
        anchors.bottom: parent.bottom
    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 3
        fillColor: root.cornerColor
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}
