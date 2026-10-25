pragma Singleton
import QtQuick

QtObject {
    property string fontName: "CaskaydiaCove Nerd Font"
    property int fontSize: 12
    property color barBg: "transparent"

    property var currentTime: new Date()
    readonly property Timer _timer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: Config.currentTime = new Date()
    }
}
