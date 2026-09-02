import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.UPower
import "../globals"
import "../ui"

MouseArea {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    property bool showTimeRemaining: false

    property var device: UPower.displayDevice
    property bool isReady: device && device.ready

    property int capacity: isReady ? Math.round(device.percentage * 100) : 0
    property bool isCharging: isReady && !UPower.onBattery

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            if (typeof globalSettingsApp !== "undefined" && globalSettingsApp) globalSettingsApp.openTab("appearance")
        } else {
            showTimeRemaining = !showTimeRemaining
        }
    }

    property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    function getIcon() {
        if (!isReady) return "󰂎";
        if (isCharging) return "󰂄";

        let index = Math.floor(capacity / 10);
        return icons[Math.max(0, Math.min(10, index))];
    }

    function getDisplayText() {
        if (!isReady) return "100%";
        if (showTimeRemaining && device) {
            let s = isCharging ? device.timeToFull : device.timeToEmpty;
            if (s > 0) {
                let h = Math.floor(s / 3600);
                let m = Math.floor((s % 3600) / 60);
                return (h > 0 ? `${h}h ` : "") + `${m}m`;
            }
        }
        return root.capacity + "%";
    }

    function getColor() {
        if (isCharging) return Colors.md3.primary;
        if (capacity <= 20) return Colors.md3.error;
        if (capacity <= 30) return Colors.md3.secondary;
        return Colors.md3.on_surface;
    }

    RowLayout {
        id: layout
        anchors.fill: parent

        QsText {
            text: getIcon() + " " + root.getDisplayText()
            color: getColor()
        }
    }
}
