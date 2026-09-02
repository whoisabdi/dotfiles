import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool wifiOn: false
    property bool btOn: false
    property bool btConnected: false
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
            BT=$(if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo '1'; else echo '0'; fi);
            BT_CONN=$(if bluetoothctl devices Connected 2>/dev/null | grep -q 'Device'; then echo '1'; else echo '0'; fi);
            if [ \"$WIFI\" = '1' ]; then
                WIFI_LINE=$(nmcli -t -f active,signal,ssid dev wifi 2>/dev/null | grep '^yes' | head -n 1);
                SIGNAL=$(echo \"$WIFI_LINE\" | cut -d: -f2);
                SSID=$(echo \"$WIFI_LINE\" | cut -d: -f3-);
            else
                SIGNAL='0';
                SSID='Disconnected';
            fi;
            if [ -z \"$SSID\" ]; then SSID='Disconnected'; SIGNAL='0'; fi;
            echo \"$WIFI|$BT|$SSID|$SIGNAL|$BT_CONN\"
        "]
        stdout: StdioCollector {
            onStreamFinished: {
                let res = text.replace(/\r/g, '').trim().split('|')
                if (res.length >= 5) {
                    root.wifiOn = (res[0] === '1')
                    root.btOn = (res[1] === '1')
                    root.currentSsid = res[2]
                    root.wifiSignal = parseInt(res[3]) || 0
                    root.btConnected = (res[4] === '1')
                }
            }
        }
    }

    Process {
        id: wifiToggleProc
        command: ["sh", "-c", "if [ $(nmcli radio wifi) = 'enabled' ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"]
        onExited: refreshTimer.restart()
    }

    Process {
        id: btToggleProc
        command: ["sh", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else bluetoothctl power on; fi"]
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
        root.btOn = !root.btOn
        btToggleProc.running = true
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
