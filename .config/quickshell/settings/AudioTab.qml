import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
                        QsText { anchors.centerIn: parent; text: "塔"; font.pixelSize: 28; color: Colors.md3.primary }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText {
                            text: outputCard.sink ? (outputCard.sink.description || outputCard.sink.name) : "Default Speaker"
                            font.pixelSize: 14; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Rectangle {
                                id: outTrack
                                Layout.fillWidth: true; height: 8; radius: 4
                                color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5); border.width: 1
                                Rectangle { width: outputCard.sink && outputCard.sink.audio ? outTrack.width * outputCard.sink.audio.volume : 0; height: parent.height; radius: 4; color: Colors.md3.primary }
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
                        QsText { anchors.centerIn: parent; text: "混"; font.pixelSize: 28; color: Colors.md3.primary }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText {
                            text: inputCard.source ? (inputCard.source.description || inputCard.source.name) : "Default Microphone"
                            font.pixelSize: 14; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Rectangle {
                                id: inTrack
                                Layout.fillWidth: true; height: 8; radius: 4
                                color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5); border.width: 1
                                Rectangle { width: inputCard.source && inputCard.source.audio ? inTrack.width * inputCard.source.audio.volume : 0; height: parent.height; radius: 4; color: Colors.md3.primary }
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
                    QsText { text: "據"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
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

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 16; spacing: 16

                        Item {
                            Layout.preferredWidth: 24; Layout.preferredHeight: 24
                            QsText { anchors.centerIn: parent; text: "紙"; font.pixelSize: 20; color: Colors.md3.primary }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            QsText { text: modelData.name || "Unknown App"; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true; font.pixelSize: 13 }
                            Rectangle {
                                id: appTrack
                                Layout.fillWidth: true; height: 8; radius: 4
                                color: Qt.alpha(Colors.md3.surface_container_highest, 0.8)
                                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5); border.width: 1
                                Rectangle { width: modelData.audio ? appTrack.width * modelData.audio.volume : 0; height: parent.height; radius: 4; color: Colors.md3.primary }
                                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onPositionChanged: (mouse) => { if(modelData.audio) modelData.audio.volume = Math.max(0, Math.min(1, mouse.x / width)) } }
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
                        QsText { anchors.centerIn: parent; text: "弊"; font.pixelSize: 24; color: Colors.md3.primary }
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
