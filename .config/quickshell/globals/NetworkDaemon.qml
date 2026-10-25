import QtQuick
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: root

    readonly property BluetoothAdapter btAdapter: Bluetooth.defaultAdapter
    property bool btOn: btAdapter ? btAdapter.enabled : false
    property bool btConnected: btAdapter ? btAdapter.devices.values.some(d => d.connected) : false

    property bool wifiOn: false
    property int wifiSignal: 0
    property string currentSsid: "Checking..."

    function getWifiIcon() {
        if (!wifiOn) return "󰤮";
        if (currentSsid === "Disconnected" || currentSsid === "Checking..." || currentSsid === "") return "󰤭";
        if (wifiSignal >= 75) return "󰤨";
        if (wifiSignal >= 50) return "󰤥";
        if (wifiSignal >= 25) return "󰤢";
        return "󰤟";
    }

    function getBtIcon() {
        if (!btOn) return "󰂲";
        if (btConnected) return "󰂱";
        return "󰂯";
    }

    Process {
        id: netStateProc
        running: true
        command: ["sh", "-c", "
            WIFI=$(if [ \"$(nmcli radio wifi 2>/dev/null)\" = 'enabled' ]; then echo '1'; else echo '0'; fi);
            if [ \"$WIFI\" = '1' ]; then
                WIFI_LINE=$(nmcli -t -f active,signal,ssid dev wifi 2>/dev/null | grep '^yes' | head -n 1);
                SIGNAL=$(echo \"$WIFI_LINE\" | cut -d: -f2);
                SSID=$(echo \"$WIFI_LINE\" | cut -d: -f3-);
            else
                SIGNAL='0';
                SSID='Disconnected';
            fi;
            if [ -z \"$SSID\" ]; then SSID='Disconnected'; SIGNAL='0'; fi;
            echo \"$WIFI|$SSID|$SIGNAL\"
        "]
        stdout: StdioCollector {
            onStreamFinished: {
                let res = text.replace(/\r/g, '').trim().split('|')
                if (res.length >= 3) {
                    root.wifiOn = (res[0] === '1')
                    root.currentSsid = res[1]
                    root.wifiSignal = parseInt(res[2]) || 0
                }
            }
        }
    }

    Process {
        id: wifiToggleProc
        command: ["sh", "-c", "if [ $(nmcli radio wifi) = 'enabled' ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"]
        onExited: refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 600
        repeat: false
        onTriggered: netStateProc.running = true
    }

    function toggleWifi() {
        root.wifiOn = !root.wifiOn
        wifiToggleProc.running = true
    }

    function toggleBt() {
        if (btAdapter) {
            btAdapter.enabled = !btAdapter.enabled
        }
    }

    function refresh() {
        netStateProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: netStateProc.running = true
    }
}
