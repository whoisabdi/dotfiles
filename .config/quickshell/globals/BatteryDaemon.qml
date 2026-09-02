import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

Item {
    id: daemon

    property var device: UPower.displayDevice
    property bool isReady: device && device.ready

    // The shield that prevents startup notification spam
    property bool isStartup: true
    Timer {
        interval: 3000
        running: true
        onTriggered: daemon.isStartup = false
    }

    property int capacity: isReady ? Math.round(device.percentage * 100) : 100
    property bool isCharging: isReady && !UPower.onBattery

    property int timeSeconds: device && device.ready ? (isCharging ? device.timeToFull : device.timeToEmpty) : 0
    property string timeEstimate: {
        if (!isReady) return "Battery state healthy"
        if (isCharging) {
            if (capacity >= fullThresh) return "Fully Charged • AC Connected"
            if (timeSeconds > 0) {
                let hrs = Math.floor(timeSeconds / 3600)
                let mins = Math.floor((timeSeconds % 3600) / 60)
                return hrs > 0 ? `${hrs}h ${mins}m until full` : `${mins}m until full`
            }
            return "Charging on AC Power"
        } else {
            if (timeSeconds > 0) {
                let hrs = Math.floor(timeSeconds / 3600)
                let mins = Math.floor((timeSeconds % 3600) / 60)
                return hrs > 0 ? `${hrs}h ${mins}m remaining` : `${mins}m remaining`
            }
            return "Discharging • System on Battery"
        }
    }

    property int lowThresh: 20
    property int critThresh: 5
    property int fullThresh: 95
    property int suspendGraceMs: 30000

    property bool notifiedLow: false
    property bool notifiedCrit: false
    property bool notifiedFull: false

    Process { id: notifyProc; property string title; property string msg; property string icon; property string urgency: "normal"; command: ["notify-send", "-a", "System Context", "-u", urgency, "-i", icon, title, msg] }
    Process { id: suspendProc; command: ["systemctl", "suspend"] }

    function sendNotif(title, msg, icon, urgency) {
        notifyProc.title = title; notifyProc.msg = msg; notifyProc.icon = icon; notifyProc.urgency = urgency || "normal"
        notifyProc.running = true
    }

    Timer {
        id: suspendTimer
        interval: daemon.suspendGraceMs
        onTriggered: {
            if (!daemon.isCharging) {
                suspendProc.running = true
            }
        }
    }

    onIsChargingChanged: {
        if (!isReady || isStartup) return;

        if (isCharging) {
            sendNotif("Charger Plugged In", `Battery is at ${capacity}%.`, "battery-charging")
            notifiedLow = false
            notifiedCrit = false
            suspendTimer.stop()
        } else {
            sendNotif("Charger Unplugged", `Battery is at ${capacity}%.`, "battery-discharging")
            notifiedFull = false
            if (capacity <= critThresh) {
                sendNotif("Battery Critically Low", `Battery is at ${capacity}%. Connect charger immediately!`, "battery-empty", "critical")
                notifiedCrit = true
                notifiedLow = true
                suspendTimer.restart()
            }
        }
    }

    onCapacityChanged: {
        if (!isReady || isStartup) return;

        if (!isCharging) {
            if (capacity <= critThresh) {
                if (!notifiedCrit) {
                    sendNotif("Battery Critically Low", `Battery is at ${capacity}%. Connect charger immediately!`, "battery-empty", "critical")
                    notifiedCrit = true
                    notifiedLow = true
                    suspendTimer.restart()
                }
            } else if (capacity <= lowThresh) {
                notifiedCrit = false
                if (!notifiedLow) {
                    sendNotif("Battery Low", `Battery is at ${capacity}%.`, "battery-low", "critical")
                    notifiedLow = true
                }
            } else {
                notifiedCrit = false
                notifiedLow = false
            }
        } else {
            if (capacity >= fullThresh && !notifiedFull) {
                sendNotif("Battery Full", "Battery is fully charged. You can unplug.", "battery-full")
                notifiedFull = true
            } else if (capacity < fullThresh) {
                notifiedFull = false
            }
        }
    }
}
