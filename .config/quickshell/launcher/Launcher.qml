import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../globals"
import "../ui"

PanelWindow {
    id: window

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "launcher"
    exclusiveZone: 0

    color: "transparent"
    visible: false

    property var allApps: []
    property var filteredApps: []

    function toggle() {
        window.visible = !window.visible
        if (window.visible) {
            allApps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
            allApps.sort((a, b) => a.name.localeCompare(b.name))
            searchField.text = ""
            filterApps()
            searchField.forceActiveFocus()
            appList.positionViewAtBeginning()
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchField.forceActiveFocus()
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { window.toggle() }
        function show(): void {
            window.visible = true
            allApps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
            allApps.sort((a, b) => a.name.localeCompare(b.name))
            searchField.text = ""
            filterApps()
            searchField.forceActiveFocus()
            appList.positionViewAtBeginning()
        }
        function hide(): void { window.visible = false }
    }

    MouseArea {
        id: bgMouse
        anchors.fill: parent
        focus: true
        onClicked: window.visible = false
        Keys.onEscapePressed: (event) => { window.visible = false; event.accepted = true; }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                window.visible = false
                event.accepted = true
            }
        }
    }

    Rectangle {
        id: launcherModal
        anchors.centerIn: parent
        width: 480
        height: 560
        color: Colors.md3.surface_container_high
        radius: 20
        border.color: Colors.md3.outline_variant
        border.width: 1
        clip: true
        focus: true

        Keys.onEscapePressed: (event) => { window.visible = false; event.accepted = true; }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                window.visible = false
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: searchField.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Search Bar Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14
                color: Colors.md3.surface_container
                border.color: searchField.activeFocus ? Colors.md3.primary : Qt.alpha(Colors.md3.outline_variant, 0.6)
                border.width: searchField.activeFocus ? 2 : 1

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    QsText {
                        text: "󰍉"
                        color: searchField.activeFocus ? Colors.md3.primary : Colors.md3.on_surface_variant
                        font.pixelSize: 18
                        Layout.preferredWidth: 22
                        horizontalAlignment: Text.AlignHCenter
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search applications..."
                        placeholderTextColor: Colors.md3.outline
                        color: Colors.md3.on_surface
                        font.family: Config.fontName
                        font.pixelSize: 14
                        background: Item {}

                        onTextChanged: filterApps()

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down) {
                                if (appList.count > 0) {
                                    appList.currentIndex = Math.min(appList.currentIndex + 1, appList.count - 1)
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                if (appList.count > 0) {
                                    appList.currentIndex = Math.max(appList.currentIndex - 1, 0)
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                let selectedApp = filteredApps[appList.currentIndex]
                                if (selectedApp) {
                                    selectedApp.execute()
                                    window.visible = false
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                window.visible = false
                                event.accepted = true
                            }
                        }
                    }

                    MouseArea {
                        visible: searchField.text.length > 0
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            searchField.text = ""
                            searchField.forceActiveFocus()
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 11
                            color: parent.containsMouse ? Colors.md3.surface_container_highest : "transparent"
                            QsText {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.pixelSize: 13
                                color: Colors.md3.on_surface_variant
                            }
                        }
                    }
                }
            }

            // Top divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.alpha(Colors.md3.outline_variant, 0.4)
            }

            // App List View
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: true
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 54
                preferredHighlightEnd: height - 54
                highlightMoveDuration: 120
                highlightMoveVelocity: -1
                model: filteredApps

                ScrollBar.vertical: ScrollBar {
                    parent: appList
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: -6
                    policy: appList.contentHeight > appList.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Colors.md3.primary
                        opacity: parent.hovered || parent.pressed ? 0.8 : 0.35
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    background: Rectangle { implicitWidth: 4; color: "transparent" }
                }

                QsText {
                    anchors.centerIn: parent
                    visible: appList.count === 0
                    text: "No applications found"
                    font.pixelSize: 14
                    font.italic: true
                    color: Colors.md3.on_surface_variant
                }

                delegate: MouseArea {
                    id: delegateArea
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: 52
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    readonly property bool isSelected: appList.currentIndex === index
                    readonly property bool isHovered: containsMouse

                    onClicked: {
                        modelData.execute()
                        window.visible = false
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: isSelected
                               ? Qt.alpha(Colors.md3.primary_container, 0.55)
                               : (isHovered ? Colors.md3.surface_container : "transparent")
                        border.color: isSelected ? Qt.alpha(Colors.md3.primary, 0.7) : "transparent"
                        border.width: isSelected ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Selected accent pill
                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: isSelected ? 24 : 0
                                radius: 1.5
                                color: Colors.md3.primary
                                visible: isSelected
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 150 } }
                            }

                            IconImage {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                source: {
                                    let icon = modelData.icon || modelData.id
                                    return Quickshell.iconPath(icon, "application-x-executable")
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                QsText {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: isSelected ? Colors.md3.primary : Colors.md3.on_surface
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QsText {
                                    visible: (modelData.genericName || modelData.comment || "").length > 0
                                    Layout.fillWidth: true
                                    text: modelData.genericName || modelData.comment || ""
                                    color: Colors.md3.on_surface_variant
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            // Launch action pill
                            Rectangle {
                                visible: isSelected
                                implicitWidth: launchRow.implicitWidth + 14
                                implicitHeight: 22
                                radius: 11
                                color: Colors.md3.primary

                                RowLayout {
                                    id: launchRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    QsText {
                                        text: "Open"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Colors.md3.on_primary
                                    }

                                    QsText {
                                        text: "↵"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Colors.md3.on_primary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.alpha(Colors.md3.outline_variant, 0.4)
            }

            // Symmetrical Footer Bar
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Layout.leftMargin: 2
                Layout.rightMargin: 2

                QsText {
                    text: filteredApps.length + (filteredApps.length === 1 ? " app" : " apps")
                    font.pixelSize: 11
                    color: Colors.md3.on_surface_variant
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 12

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 14; height: 14; radius: 3
                            color: Colors.md3.surface_container_highest
                            QsText { anchors.centerIn: parent; text: "↑↓"; font.pixelSize: 9; color: Colors.md3.on_surface_variant }
                        }
                        QsText { text: "Navigate"; font.pixelSize: 11; color: Colors.md3.on_surface_variant }
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 14; height: 14; radius: 3
                            color: Colors.md3.surface_container_highest
                            QsText { anchors.centerIn: parent; text: "↵"; font.pixelSize: 9; color: Colors.md3.on_surface_variant }
                        }
                        QsText { text: "Open"; font.pixelSize: 11; color: Colors.md3.on_surface_variant }
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 24; height: 14; radius: 3
                            color: Colors.md3.surface_container_highest
                            QsText { anchors.centerIn: parent; text: "Esc"; font.pixelSize: 9; color: Colors.md3.on_surface_variant }
                        }
                        QsText { text: "Close"; font.pixelSize: 11; color: Colors.md3.on_surface_variant }
                    }
                }
            }
        }
    }

    function filterApps() {
        let query = searchField.text.toLowerCase().trim()
        if (query.length === 0) {
            filteredApps = allApps
        } else {
            filteredApps = allApps.filter(app => {
                let nameMatch = app.name.toLowerCase().includes(query)
                let genMatch = app.genericName && app.genericName.toLowerCase().includes(query)
                let commMatch = app.comment && app.comment.toLowerCase().includes(query)
                return nameMatch || genMatch || commMatch
            })
        }
        appList.currentIndex = 0
    }
}
