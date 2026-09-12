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
        width: 360
        height: 520
        color: Colors.md3.surface_container_high
        radius: 28
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
            anchors.margins: 14
            spacing: 10

            // Search Bar Header (matching pill shape)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
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
                        font.pixelSize: 17
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignHCenter
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search apps..."
                        placeholderTextColor: Colors.md3.outline
                        color: Colors.md3.on_surface
                        font.family: Config.fontName
                        font.pixelSize: 13
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
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            searchField.text = ""
                            searchField.forceActiveFocus()
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: parent.containsMouse ? Colors.md3.surface_container_highest : "transparent"
                            QsText {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.pixelSize: 12
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
                color: Qt.alpha(Colors.md3.outline_variant, 0.35)
            }

            // App List View
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: true
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 48
                preferredHighlightEnd: height - 48
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
                        implicitWidth: 3
                        radius: 1.5
                        color: Colors.md3.primary
                        opacity: parent.hovered || parent.pressed ? 0.8 : 0.35
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    background: Rectangle { implicitWidth: 3; color: "transparent" }
                }

                QsText {
                    anchors.centerIn: parent
                    visible: appList.count === 0
                    text: "No applications found"
                    font.pixelSize: 13
                    font.italic: true
                    color: Colors.md3.on_surface_variant
                }

                delegate: MouseArea {
                    id: delegateArea
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: 46
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    readonly property bool isSelected: appList.currentIndex === index
                    readonly property bool isHovered: containsMouse

                    onClicked: {
                        modelData.execute()
                        window.visible = false
                    }

                    // Rounded pill highlight
                    Rectangle {
                        anchors.fill: parent
                        radius: 23
                        color: isSelected
                               ? Colors.md3.primary_container
                               : (isHovered ? Qt.alpha(Colors.md3.surface_container, 0.8) : "transparent")
                        border.color: isSelected ? Qt.alpha(Colors.md3.primary, 0.5) : "transparent"
                        border.width: isSelected ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 12
                            spacing: 12

                            IconImage {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                source: {
                                    let icon = modelData.icon || modelData.id
                                    return Quickshell.iconPath(icon, "application-x-executable")
                                }
                            }

                            QsText {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: isSelected ? Colors.md3.on_primary_container : Colors.md3.on_surface
                                font.pixelSize: 13
                                font.bold: isSelected
                                elide: Text.ElideRight
                            }

                            // Launch action pill
                            Rectangle {
                                visible: isSelected
                                width: 22
                                height: 22
                                radius: 11
                                color: Colors.md3.primary

                                QsText {
                                    anchors.centerIn: parent
                                    text: "↵"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Colors.md3.on_primary
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
                color: Qt.alpha(Colors.md3.outline_variant, 0.35)
            }

            // Symmetrical Compact Footer
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Layout.leftMargin: 4
                Layout.rightMargin: 4

                QsText {
                    text: filteredApps.length + (filteredApps.length === 1 ? " app" : " apps")
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
                }

                Item { Layout.fillWidth: true }

                QsText {
                    text: "↵ Launch  •  ⎋ Close"
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
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
