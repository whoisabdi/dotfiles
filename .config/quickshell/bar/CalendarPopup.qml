import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../globals"
import "../ui"

PanelWindow {
    id: window
    objectName: "calendar"

    anchors { top: true; right: true }
    margins { top: 54; right: 48 }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "calendar"
    exclusiveZone: 0

    color: "transparent"
    visible: false

    HyprlandFocusGrab {
        active: window.visible
        windows: [window]
        onCleared: window.visible = false
    }

    property var selectedDate: new Date()
    property int viewYear: selectedDate.getFullYear()
    property int viewMonth: selectedDate.getMonth()

    function toggle() {
        window.visible = !window.visible
        if (window.visible) {
            resetToToday()
        }
    }

    function resetToToday() {
        let now = new Date()
        selectedDate = now
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11
            viewYear--
        } else {
            viewMonth--
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0
            viewYear++
        } else {
            viewMonth++
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { window.toggle() }
        function show(): void { window.visible = true; window.resetToToday() }
        function hide(): void { window.visible = false }
    }

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    readonly property var dayLabels: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    // Generates 42 calendar cells (6 rows x 7 days) for currently viewed month
    readonly property var calendarDays: {
        let cells = []
        let firstDay = new Date(viewYear, viewMonth, 1).getDay()
        let daysInCurrentMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        let daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate()

        let today = new Date()
        let isCurrentMonth = (today.getFullYear() === viewYear && today.getMonth() === viewMonth)

        // Previous month filler days
        for (let i = firstDay - 1; i >= 0; i--) {
            cells.push({
                day: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false
            })
        }

        // Current month days
        for (let d = 1; d <= daysInCurrentMonth; d++) {
            cells.push({
                day: d,
                isCurrentMonth: true,
                isToday: isCurrentMonth && (today.getDate() === d)
            })
        }

        // Next month filler days
        let remaining = 42 - cells.length
        for (let n = 1; n <= remaining; n++) {
            cells.push({
                day: n,
                isCurrentMonth: false,
                isToday: false
            })
        }

        return cells
    }

    Rectangle {
        id: card
        width: 330
        implicitHeight: contentCol.implicitHeight + 36
        radius: 20
        color: Colors.md3.surface_container_high
        border.color: Colors.md3.outline_variant
        border.width: 1
        clip: true

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // Top Header: Live Digital Clock & Full Date
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    QsText {
                        text: Qt.formatDateTime(Config.currentTime, "hh:mm:ss AP")
                        font.pixelSize: 22
                        font.bold: true
                        color: Colors.md3.primary
                    }
                    Item { Layout.fillWidth: true }
                    // Quick "Today" Jump Button
                    MouseArea {
                        implicitWidth: todayBadge.implicitWidth
                        implicitHeight: todayBadge.implicitHeight
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.resetToToday()

                        Rectangle {
                            id: todayBadge
                            implicitWidth: todayText.implicitWidth + 12
                            implicitHeight: 22
                            radius: 11
                            color: Qt.alpha(Colors.md3.primary, 0.15)
                            border.color: Qt.alpha(Colors.md3.primary, 0.4)
                            border.width: 1

                            QsText {
                                id: todayText
                                anchors.centerIn: parent
                                text: "Today"
                                font.pixelSize: 11
                                font.bold: true
                                color: Colors.md3.primary
                            }
                        }
                    }
                }

                QsText {
                    text: Qt.formatDateTime(Config.currentTime, "dddd, MMMM d, yyyy")
                    font.pixelSize: 12
                    color: Colors.md3.on_surface_variant
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.alpha(Colors.md3.outline_variant, 0.5)
            }

            // Month Navigation Row (< October 2026 >)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                QsText {
                    text: `${window.monthNames[window.viewMonth]} ${window.viewYear}`
                    font.pixelSize: 15
                    font.bold: true
                    color: Colors.md3.on_surface
                    Layout.fillWidth: true
                }

                // Prev Button
                MouseArea {
                    implicitWidth: 28; implicitHeight: 28
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.prevMonth()

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: parent.containsMouse ? Qt.alpha(Colors.md3.surface_variant, 0.6) : "transparent"
                        QsText {
                            anchors.centerIn: parent
                            text: "󰅁"
                            font.pixelSize: 14
                            color: Colors.md3.on_surface
                        }
                    }
                }

                // Next Button
                MouseArea {
                    implicitWidth: 28; implicitHeight: 28
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.nextMonth()

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: parent.containsMouse ? Qt.alpha(Colors.md3.surface_variant, 0.6) : "transparent"
                        QsText {
                            anchors.centerIn: parent
                            text: "󰅂"
                            font.pixelSize: 14
                            color: Colors.md3.on_surface
                        }
                    }
                }
            }

            // Days of the Week Header Row (Su Mo Tu We Th Fr Sa)
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: window.dayLabels
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: 22
                        QsText {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.bold: true
                            color: (index === 0 || index === 6) ? Colors.md3.secondary : Colors.md3.on_surface_variant
                        }
                    }
                }
            }

            // 6x7 Calendar Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 4

                Repeater {
                    model: window.calendarDays

                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        Rectangle {
                            id: dayCircle
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            color: modelData.isToday ? Colors.md3.primary : (dayMa.containsMouse ? Qt.alpha(Colors.md3.surface_variant, 0.7) : "transparent")

                            Behavior on color { ColorAnimation { duration: 150 } }

                            QsText {
                                anchors.centerIn: parent
                                text: modelData.day.toString()
                                font.pixelSize: 12
                                font.bold: modelData.isToday
                                color: modelData.isToday ? Colors.md3.on_primary : (modelData.isCurrentMonth ? Colors.md3.on_surface : Qt.alpha(Colors.md3.on_surface_variant, 0.35))
                            }
                        }

                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}
