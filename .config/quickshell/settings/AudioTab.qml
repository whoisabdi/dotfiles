import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../globals"
import "../ui"
import "../osd"

ScrollView {
    id: scrollRoot
    required property var rootApp
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        parent: scrollRoot
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 4
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Colors.md3.primary
            opacity: parent.hovered || parent.pressed ? 0.8 : 0.35
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        background: Rectangle { implicitWidth: 4; color: "transparent" }
    }

    ColumnLayout {
        width: scrollRoot.availableWidth - 12
        spacing: 20

        QsText { text: "Audio & Media"; font.pixelSize: 24; font.bold: true; color: Colors.md3.on_surface }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 12
            QsText { text: "Output Device"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

            Rectangle {
                id: outputCard
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1
                property var sink: Pipewire.defaultAudioSink
                PwObjectTracker { objects: outputCard.sink ? [outputCard.sink] : [] }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16

                    Item {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        QsText {
                            anchors.centerIn: parent
                            text: outputCard.sink && outputCard.sink.audio && outputCard.sink.audio.muted ? "󰝟" : "󰕾"
                            font.pixelSize: 26
                            color: outputCard.sink && outputCard.sink.audio && outputCard.sink.audio.muted ? Colors.md3.error : Colors.md3.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            QsText {
                                text: outputCard.sink ? (outputCard.sink.description || outputCard.sink.name) : "Default Speaker"
                                font.pixelSize: 14; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            MouseArea {
                                implicitWidth: 26; implicitHeight: 26
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (outputCard.sink && outputCard.sink.audio) {
                                        outputCard.sink.audio.muted = !outputCard.sink.audio.muted
                                    }
                                }
                                QsText {
                                    anchors.centerIn: parent
                                    text: outputCard.sink && outputCard.sink.audio && outputCard.sink.audio.muted ? "󰝟" : "󰕾"
                                    font.pixelSize: 15
                                    color: outputCard.sink && outputCard.sink.audio && outputCard.sink.audio.muted ? Colors.md3.error : Colors.md3.on_surface_variant
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Rectangle {
                                id: outTrack
                                Layout.fillWidth: true; height: 8; radius: 4
                                color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5); border.width: 1
                                Rectangle { width: outputCard.sink && outputCard.sink.audio ? outTrack.width * outputCard.sink.audio.volume : 0; height: parent.height; radius: 4; color: outputCard.sink && outputCard.sink.audio && outputCard.sink.audio.muted ? Colors.md3.outline : Colors.md3.primary }
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onPressed: (mouse) => updateVol(mouse.x); onPositionChanged: (mouse) => updateVol(mouse.x)
                                    function updateVol(mx) { if (outputCard.sink && outputCard.sink.audio) outputCard.sink.audio.volume = Math.max(0, Math.min(1, mx / outTrack.width)) }
                                }
                            }
                            QsText { text: outputCard.sink && outputCard.sink.audio ? Math.round(outputCard.sink.audio.volume * 100) + "%" : "0%"; font.pixelSize: 12; font.bold: true; color: Colors.md3.on_surface_variant }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 12
            QsText { text: "Input Device"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

            Rectangle {
                id: inputCard
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1
                property var source: Pipewire.defaultAudioSource
                PwObjectTracker { objects: inputCard.source ? [inputCard.source] : [] }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16

                    Item {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        QsText {
                            anchors.centerIn: parent
                            text: inputCard.source && inputCard.source.audio && inputCard.source.audio.muted ? "󰍭" : "󰍬"
                            font.pixelSize: 26
                            color: inputCard.source && inputCard.source.audio && inputCard.source.audio.muted ? Colors.md3.error : Colors.md3.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            QsText {
                                text: inputCard.source ? (inputCard.source.description || inputCard.source.name) : "Default Microphone"
                                font.pixelSize: 14; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            MouseArea {
                                implicitWidth: 26; implicitHeight: 26
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (inputCard.source && inputCard.source.audio) {
                                        inputCard.source.audio.muted = !inputCard.source.audio.muted
                                    }
                                }
                                QsText {
                                    anchors.centerIn: parent
                                    text: inputCard.source && inputCard.source.audio && inputCard.source.audio.muted ? "󰍭" : "󰍬"
                                    font.pixelSize: 15
                                    color: inputCard.source && inputCard.source.audio && inputCard.source.audio.muted ? Colors.md3.error : Colors.md3.on_surface_variant
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Rectangle {
                                id: inTrack
                                Layout.fillWidth: true; height: 8; radius: 4
                                color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5); border.width: 1
                                Rectangle { width: inputCard.source && inputCard.source.audio ? inTrack.width * inputCard.source.audio.volume : 0; height: parent.height; radius: 4; color: inputCard.source && inputCard.source.audio && inputCard.source.audio.muted ? Colors.md3.outline : Colors.md3.primary }
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onPressed: (mouse) => updateVol(mouse.x); onPositionChanged: (mouse) => updateVol(mouse.x)
                                    function updateVol(mx) { if (inputCard.source && inputCard.source.audio) inputCard.source.audio.volume = Math.max(0, Math.min(1, mx / inTrack.width)) }
                                }
                            }
                            QsText { text: inputCard.source && inputCard.source.audio ? Math.round(inputCard.source.audio.volume * 100) + "%" : "0%"; font.pixelSize: 12; font.bold: true; color: Colors.md3.on_surface_variant }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 12; Layout.topMargin: 8
            QsText { text: "Application Mixer"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

            PwObjectTracker { objects: Pipewire.nodes.values }

            property var appNodes: Pipewire.nodes.values.filter(n => n.mediaClass === "Stream/Output/Audio" && n.audio !== null)

            Rectangle {
                visible: parent.appNodes.length === 0
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 12
                color: Colors.md3.surface_container
                border.color: Colors.md3.outline_variant
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    QsText { text: "󰝟"; font.pixelSize: 18; color: Colors.md3.on_surface_variant }
                    QsText {
                        text: "No applications are currently playing audio."
                        font.pixelSize: 12
                        color: Colors.md3.on_surface_variant
                    }
                }
            }

            Repeater {
                model: parent.appNodes
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 64; radius: 12
                    color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1
                    PwObjectTracker { objects: [modelData] }

                    readonly property string appIconSource: {
                        let icon = modelData.properties["application.icon-name"]
                        if (icon && Quickshell.iconPath(icon, "") !== "") return Quickshell.iconPath(icon, "")
                        let binary = modelData.properties["application.process.binary"]
                        if (binary && Quickshell.iconPath(binary, "") !== "") return Quickshell.iconPath(binary, "")
                        let nodeName = modelData.properties["node.name"]
                        if (nodeName && Quickshell.iconPath(nodeName, "") !== "") return Quickshell.iconPath(nodeName, "")
                        return Quickshell.iconPath("audio-card", "audio-card")
                    }

                    readonly property string streamTitle: {
                        const app = modelData.properties["application.name"] || (modelData.description !== "" ? modelData.description : modelData.name) || "Application"
                        const media = modelData.properties["media.name"]
                        return media ? `${app} • ${media}` : app
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 14

                        Item {
                            Layout.preferredWidth: 26; Layout.preferredHeight: 26
                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 24
                                source: appIconSource
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                QsText {
                                    text: streamTitle
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    implicitWidth: 24; implicitHeight: 24
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.audio) {
                                            modelData.audio.muted = !modelData.audio.muted
                                        }
                                    }
                                    QsText {
                                        anchors.centerIn: parent
                                        text: modelData.audio && modelData.audio.muted ? "󰝟" : "󰕾"
                                        font.pixelSize: 15
                                        color: modelData.audio && modelData.audio.muted ? Colors.md3.error : Colors.md3.on_surface_variant
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true; spacing: 12
                                Rectangle {
                                    id: appTrack
                                    Layout.fillWidth: true; height: 8; radius: 4
                                    color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                                    border.color: Qt.alpha(Colors.md3.outline_variant, 0.5); border.width: 1
                                    Rectangle {
                                        width: modelData.audio ? appTrack.width * modelData.audio.volume : 0
                                        height: parent.height; radius: 4
                                        color: modelData.audio && modelData.audio.muted ? Colors.md3.outline : Colors.md3.primary
                                    }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => updateVol(mouse.x)
                                        onPositionChanged: (mouse) => updateVol(mouse.x)
                                        function updateVol(mx) {
                                            if (modelData.audio) {
                                                modelData.audio.volume = Math.max(0, Math.min(1, mx / appTrack.width))
                                            }
                                        }
                                    }
                                }
                                QsText {
                                    text: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : "0%"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Colors.md3.on_surface_variant
                                }
                            }
                        }
                    }
                }
            }
        }

        // Advanced Audio Tools
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            Layout.topMargin: 8

            QsText { text: "Advanced Audio Configuration"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

            Process { id: pavuProc; command: ["pavucontrol"] }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 64; radius: 12
                color: Colors.md3.surface_container; border.color: Colors.md3.outline_variant; border.width: 1

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { rootApp.visible = false; pavuProc.running = true }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 14

                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        QsText { anchors.centerIn: parent; text: "󰓃"; font.pixelSize: 24; color: Colors.md3.primary }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "Volume Control (Pavucontrol)"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: "Configure audio streams, codec profiles, input levels, and fallback sinks"; font.pixelSize: 12; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    QsText { text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 20 }
    }
}
