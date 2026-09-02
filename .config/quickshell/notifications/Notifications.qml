import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../globals"
import "../ui"

PanelWindow {
    id: window
    objectName: "notifications"

    anchors { top: true; right: true }
    margins { top: 12; right: 12 }

    property var popupNotifications: []
    property var historyNotifications: []
    property alias activeNotifications: window.popupNotifications
    property bool dndEnabled: false

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void {
            window.dndEnabled = !window.dndEnabled;
            if (window.dndEnabled) window.popupNotifications = [];
        }
        function setDnd(enable: bool): void {
            window.dndEnabled = enable;
            if (window.dndEnabled) window.popupNotifications = [];
        }
    }

    function dismissPopup(n) {
        if (!n) return;
        let list = window.popupNotifications.slice();
        let idx = list.indexOf(n);
        if (idx !== -1) {
            list.splice(idx, 1);
            window.popupNotifications = list;
        }
    }

    function dismissNotification(n) {
        if (!n) return;
        let pList = window.popupNotifications.slice();
        let pIdx = pList.indexOf(n);
        if (pIdx !== -1) {
            pList.splice(pIdx, 1);
            window.popupNotifications = pList;
        }
        let hList = window.historyNotifications.slice();
        let hIdx = hList.indexOf(n);
        if (hIdx !== -1) {
            hList.splice(hIdx, 1);
            window.historyNotifications = hList;
        }
        try {
            if (typeof n.dismiss === "function") {
                n.dismiss();
            }
        } catch (e) {}
    }

    function dismissAll() {
        let all = window.popupNotifications.concat(window.historyNotifications);
        window.popupNotifications = [];
        window.historyNotifications = [];
        for (let n of all) {
            if (n) {
                try {
                    if (typeof n.dismiss === "function") {
                        n.dismiss();
                    }
                } catch (e) {}
            }
        }
    }

    visible: popupNotifications.length > 0
    implicitWidth: 320
    implicitHeight: mainColumn.implicitHeight

    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notifications"

    NotificationServer {
        id: notifServer
        bodySupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: (notification) => {
            notification.tracked = true;

            // Only show toast popups on screen if DND is disabled, or urgency is Critical
            if (!window.dndEnabled || notification.urgency === NotificationUrgency.Critical) {
                let pList = window.popupNotifications.slice();
                pList.unshift(notification);
                window.popupNotifications = pList;
            }

            let hList = window.historyNotifications.slice();
            hList.unshift(notification);
            if (hList.length > 50) {
                let discarded = hList.pop();
                if (discarded && window.popupNotifications.indexOf(discarded) === -1) {
                    try { discarded.dismiss(); } catch (e) {}
                }
            }
            window.historyNotifications = hList;

            notification.closed.connect(() => {
                let currentPopups = window.popupNotifications.slice();
                let pIndex = currentPopups.indexOf(notification);
                if (pIndex !== -1) {
                    currentPopups.splice(pIndex, 1);
                    window.popupNotifications = currentPopups;
                }
                let currentHistory = window.historyNotifications.slice();
                let hIndex = currentHistory.indexOf(notification);
                if (hIndex !== -1) {
                    currentHistory.splice(hIndex, 1);
                    window.historyNotifications = currentHistory;
                }
            });
        }
    }

    ColumnLayout {
        id: mainColumn
        width: 320
        spacing: 8

        // Notification Cards
        Repeater {
            model: window.popupNotifications

            delegate: MouseArea {
                id: notifArea
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: cardRect.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical
                readonly property bool isLow: modelData.urgency === NotificationUrgency.Low
                readonly property bool isNormal: !isCritical && !isLow

                readonly property color accentColor: isCritical
                    ? Colors.md3.error
                    : (isLow ? Colors.md3.tertiary : Colors.md3.primary)

                readonly property color containerColor: isCritical
                    ? Qt.alpha(Colors.md3.error_container, 0.45)
                    : (isLow ? Qt.alpha(Colors.md3.tertiary_container, 0.40) : Qt.alpha(Colors.md3.primary_container, 0.40))

                readonly property color onContainerColor: isCritical
                    ? Colors.md3.on_error_container
                    : (isLow ? Colors.md3.on_tertiary_container : Colors.md3.on_primary_container)

                // Auto-dismiss Timer: Critical notifications NEVER auto-dismiss.
                Timer {
                    id: dismissTimer
                    interval: (modelData.expireTimeout > 0)
                        ? modelData.expireTimeout
                        : (modelData.urgency === NotificationUrgency.Low ? 4000 : 6000)
                    running: modelData.urgency !== NotificationUrgency.Critical && !notifArea.containsMouse
                    repeat: false
                    onTriggered: window.dismissPopup(modelData)
                }

                onClicked: window.dismissNotification(modelData)

                Rectangle {
                    id: cardRect
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: cardContent.implicitHeight + 24
                    color: Qt.alpha(Colors.md3.surface_container, 0.88)
                    radius: 14
                    border.color: isCritical
                        ? Colors.md3.error
                        : (notifArea.containsMouse ? notifArea.accentColor : Qt.alpha(notifArea.accentColor, 0.40))
                    border.width: isCritical ? 1.5 : 1
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Header: App Name, Urgency Badge & Dismiss Icon
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            IconImage {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                source: modelData.appIcon
                                    ? modelData.appIcon
                                    : Quickshell.iconPath(modelData.appName || "dialog-information", "application-x-executable")
                            }

                            QsText {
                                Layout.fillWidth: true
                                text: modelData.appName || "Notification"
                                font.pixelSize: 11
                                font.bold: true
                                color: notifArea.accentColor
                                elide: Text.ElideRight
                            }

                            // Urgency Badge
                            Rectangle {
                                implicitWidth: urgencyBadgeText.implicitWidth + 10
                                implicitHeight: 16
                                radius: 8
                                color: notifArea.isCritical
                                    ? Colors.md3.error
                                    : (notifArea.isLow ? Qt.alpha(Colors.md3.tertiary, 0.20) : Qt.alpha(Colors.md3.primary, 0.20))
                                border.color: notifArea.isCritical ? Colors.md3.error : Qt.alpha(notifArea.accentColor, 0.50)
                                border.width: 1

                                QsText {
                                    id: urgencyBadgeText
                                    anchors.centerIn: parent
                                    text: notifArea.isCritical ? "URGENT" : (notifArea.isLow ? "LOW" : "NORMAL")
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: notifArea.isCritical ? Colors.md3.on_error : notifArea.accentColor
                                }
                            }

                            // Dismiss button
                            MouseArea {
                                implicitWidth: 18
                                implicitHeight: 18
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: window.dismissNotification(modelData)

                                QsText {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.pixelSize: 11
                                    color: parent.containsMouse ? Colors.md3.error : Colors.md3.on_surface_variant
                                }
                            }
                        }

                        // Body: Image + Title + Content
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                visible: !!modelData.image
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                radius: 8
                                color: notifArea.containerColor
                                border.color: Qt.alpha(notifArea.accentColor, 0.35)
                                border.width: 1

                                IconImage {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: modelData.image || ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QsText {
                                    Layout.fillWidth: true
                                    text: modelData.summary
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: notifArea.isCritical ? Colors.md3.error : Colors.md3.on_surface
                                    elide: Text.ElideRight
                                }

                                QsText {
                                    Layout.fillWidth: true
                                    visible: modelData.body.length > 0
                                    text: modelData.body
                                    font.pixelSize: 12
                                    color: Colors.md3.on_surface_variant
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Notification Actions
                        RowLayout {
                            Layout.fillWidth: true
                            visible: modelData.actions && modelData.actions.length > 0
                            spacing: 6

                            Repeater {
                                model: modelData.actions
                                delegate: Rectangle {
                                    implicitWidth: actionText.implicitWidth + 14
                                    implicitHeight: 22
                                    radius: 6
                                    color: actionMouse.containsMouse ? notifArea.accentColor : notifArea.containerColor
                                    border.color: Qt.alpha(notifArea.accentColor, 0.40)
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            modelData.invokeAction(modelData.actions[index].id);
                                            window.dismissNotification(modelData);
                                        }
                                    }

                                    QsText {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: modelData.actions[index].text
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: actionMouse.containsMouse
                                            ? (notifArea.isCritical ? Colors.md3.on_error : Colors.md3.on_primary)
                                             : notifArea.onContainerColor
                                     }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Right-Aligned Clear All Button Below Notifications
        MouseArea {
            visible: window.popupNotifications.length > 1
            Layout.alignment: Qt.AlignRight
            implicitWidth: 88
            implicitHeight: 24
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: window.dismissAll()

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: parent.containsMouse ? Colors.md3.error : Qt.alpha(Colors.md3.surface_container_high, 0.85)
                border.color: parent.containsMouse ? Colors.md3.error : Qt.alpha(Colors.md3.outline_variant, 0.5)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    QsText {
                        text: "󰅖"
                        font.pixelSize: 10
                        color: parent.parent.parent.containsMouse ? Colors.md3.on_error : Colors.md3.error
                    }

                    QsText {
                        text: "Clear All"
                        font.pixelSize: 11
                        font.bold: true
                        color: parent.parent.parent.containsMouse ? Colors.md3.on_error : Colors.md3.on_surface
                    }
                }
            }
        }
    }
}
