import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
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
        spacing: 24

        QsText {
            text: "Appearance"
            font.pixelSize: 24
            font.bold: true
            color: Colors.md3.on_surface
            Layout.topMargin: 4
        }

        // Display Settings
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            QsText { text: "Display"; font.pixelSize: 15; font.bold: true; color: Colors.md3.primary }
            BrightnessSliderCard {}
        }

        // Wallpaper Engine
        ColumnLayout {
            Layout.fillWidth: true; spacing: 14
            QsText { text: "Wallpapers"; font.pixelSize: 15; font.bold: true; color: Colors.md3.primary }

            Process {
                id: getWallsProc
                running: globalState.wallpaperCache.length === 0
                command: ["bash", Paths.qsRoot + "/scripts/wallpaper.sh", "--list"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let res = text.replace(/\r/g, '').trim()
                        if (res) globalState.wallpaperCache = res.split("\n")
                    }
                }
                stderr: StdioCollector {
                    onStreamFinished: {
                        if (text.trim() !== "") console.warn("[Wallpaper Engine] List Error: " + text.trim())
                    }
                }
            }

            Process { id: applyWallProc }

            // Constrained inner ScrollView
            ScrollView {
                id: innerWallScroll
                Layout.fillWidth: true
                Layout.preferredHeight: 268
                clip: true
                contentWidth: availableWidth
                contentHeight: wallGrid.implicitHeight // Crucial: explicitly tells the ScrollView how tall the grid is

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Colors.md3.primary; opacity: 0.5 }
                }

                GridLayout {
                    id: wallGrid
                    width: innerWallScroll.availableWidth
                    columns: 3
                    columnSpacing: 14
                    rowSpacing: 14

                    Repeater {
                        model: globalState.wallpaperCache

                        delegate: Rectangle {
                            id: wallCard
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 120
                            radius: 16
                            color: Colors.md3.surface_container
                            border.color: wallMouse.containsMouse ? Colors.md3.primary : Qt.alpha(Colors.md3.outline_variant, 0.4)
                            border.width: wallMouse.containsMouse ? 2 : 1
                            clip: true

                            z: wallMouse.containsMouse ? 2 : 1
                            scale: wallMouse.containsMouse ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            property var paths: modelData.split("|")
                            property string realPath: paths[0] || ""
                            property string thumbPath: paths[1] || ""

                            Image {
                                anchors.fill: parent
                                source: wallCard.thumbPath ? ("file://" + wallCard.thumbPath) : (wallCard.realPath ? ("file://" + wallCard.realPath) : "")
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize: Qt.size(240, 150)
                                mipmap: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.alpha("black", wallMouse.containsMouse ? 0.6 : 0.2) }
                                }
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 10
                                width: pillRow.implicitWidth + 16
                                height: 26
                                radius: 13
                                color: Colors.md3.primary
                                opacity: wallMouse.containsMouse ? 1 : 0
                                transform: Translate { y: wallMouse.containsMouse ? 0 : 4 }

                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                                RowLayout {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    QsText { text: "󰄬"; font.pixelSize: 14; color: Colors.md3.on_primary }
                                    QsText { text: "Apply"; font.pixelSize: 11; font.bold: true; color: Colors.md3.on_primary }
                                }
                            }

                            MouseArea {
                                id: wallMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (!wallCard.realPath) return
                                    applyWallProc.command = ["bash", Paths.qsRoot + "/scripts/wallpaper.sh", "--set", wallCard.realPath.trim()]
                                    applyWallProc.running = true
                                }
                            }
                        }
                    }
                }
            }
        }

        // Advanced Theming & GUI Customizers
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 14
            Layout.topMargin: 12

            QsText { text: "Advanced Theming & Fonts"; font.pixelSize: 15; font.bold: true; color: Colors.md3.primary }

            Process { id: nwgProc; command: ["nwg-look"] }
            Process { id: qt5ctProc; command: ["qt5ct"] }
            Process { id: qt6ctProc; command: ["qt6ct"] }

            // 1. GTK Theme & Cursor Editor (nwg-look)
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16
                color: Colors.md3.surface_container
                border.color: Colors.md3.outline_variant; border.width: 1

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { rootApp.visible = false; nwgProc.running = true }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        radius: 12
                        color: Colors.md3.secondary_container

                        QsText {
                            anchors.centerIn: parent
                            text: "󰏘"
                            font.pixelSize: 20
                            color: Colors.md3.on_secondary_container
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "GTK Appearance Settings"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: "Change GTK 3/4 themes, cursor packs, icon sets, and system fonts"; font.pixelSize: 12; color: Qt.alpha(Colors.md3.on_surface_variant, 0.8); elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        radius: 14
                        color: Colors.md3.surface_variant
                        QsText { anchors.centerIn: parent; text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
                    }
                }
            }

            // 2. Qt5 Configuration (qt5ct)
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16
                color: Colors.md3.surface_container
                border.color: Colors.md3.outline_variant; border.width: 1

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { rootApp.visible = false; qt5ctProc.running = true }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        radius: 12
                        color: Colors.md3.tertiary_container

                        QsText {
                            anchors.centerIn: parent
                            text: "󰕰"
                            font.pixelSize: 20
                            color: Colors.md3.on_tertiary_container
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "Qt5 Appearance Settings"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: "Manage Qt5 palette overrides, icon styles, and dialog fonts"; font.pixelSize: 12; color: Qt.alpha(Colors.md3.on_surface_variant, 0.8); elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        radius: 14
                        color: Colors.md3.surface_variant
                        QsText { anchors.centerIn: parent; text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
                    }
                }
            }

            // 3. Qt6 Configuration (qt6ct)
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16
                color: Colors.md3.surface_container
                border.color: Colors.md3.outline_variant; border.width: 1

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { rootApp.visible = false; qt6ctProc.running = true }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        radius: 12
                        color: Colors.md3.tertiary_container

                        QsText {
                            anchors.centerIn: parent
                            text: "󰕰"
                            font.pixelSize: 20
                            color: Colors.md3.on_tertiary_container
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        QsText { text: "Qt6 Appearance Settings"; font.pixelSize: 15; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                        QsText { text: "Manage Qt6 palette overrides, icon styles, and dialog fonts"; font.pixelSize: 12; color: Qt.alpha(Colors.md3.on_surface_variant, 0.8); elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        radius: 14
                        color: Colors.md3.surface_variant
                        QsText { anchors.centerIn: parent; text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 24 }
    }
}
