import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Services.UPower
import "../globals"
import "../ui"

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
        id: root
        width: scrollRoot.availableWidth - 12
        spacing: 20

    QsText {
        text: "System & Hardware"
        font.pixelSize: 24
        font.bold: true
        color: Colors.md3.on_surface
    }

    property string osName: "Arch Linux"
    property string kernelVer: "Loading..."
    property string uptimeStr: "Loading..."
    property string cpuName: "Loading..."
    property string memStr: "Loading..."

    Process {
        id: sysInfoProc
        running: true
        command: ["sh", "-c", "
            KERNEL=$(uname -r);
            UPTIME=$(uptime -p | sed 's/up //');
            CPU=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs);
            MEM=$(free -h | awk '/^Mem:/ {print $3 \" / \" $2}');
            echo \"$KERNEL|$UPTIME|$CPU|$MEM\"
        "]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split("|")
                if (parts.length >= 4) {
                    root.kernelVer = parts[0]
                    root.uptimeStr = parts[1]
                    root.cpuName = parts[2]
                    root.memStr = parts[3]
                }
            }
        }
    }

    // 1. Device & OS Specs Card
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        QsText { text: "Device Specification"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            radius: 12
            color: Colors.md3.surface_container
            border.color: Colors.md3.outline_variant
            border.width: 1

            GridLayout {
                anchors.fill: parent
                anchors.margins: 16
                columns: 2
                columnSpacing: 16
                rowSpacing: 8

                QsText { text: "󰣇 OS"; font.pixelSize: 13; font.bold: true; color: Colors.md3.primary }
                QsText { text: "Arch Linux (Rolling Release) • Wayland"; font.pixelSize: 13; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }

                QsText { text: "󰌢 Host & Kernel"; font.pixelSize: 13; font.bold: true; color: Colors.md3.primary }
                QsText { text: "empire • " + root.kernelVer; font.pixelSize: 13; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }

                QsText { text: "󰍛 Processor"; font.pixelSize: 13; font.bold: true; color: Colors.md3.primary }
                QsText { text: root.cpuName; font.pixelSize: 13; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }

                QsText { text: "󰘚 Memory & Uptime"; font.pixelSize: 13; font.bold: true; color: Colors.md3.primary }
                QsText { text: root.memStr + " • Up " + root.uptimeStr; font.pixelSize: 13; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }
    }

    // 2. Battery & Power Status Card
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        QsText { text: "Power & Battery"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            radius: 12
            color: Colors.md3.surface_container
            border.color: Colors.md3.outline_variant
            border.width: 1

            property var dev: UPower.displayDevice
            property bool isReady: dev && dev.ready
            property int cap: isReady ? Math.round(dev.percentage * 100) : 100
            property bool isCharging: isReady && !UPower.onBattery

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Item {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28
                    QsText {
                        anchors.centerIn: parent
                        text: parent.parent.parent.isCharging ? "󰂄" : "󰁹"
                        font.pixelSize: 26
                        color: parent.parent.parent.isCharging ? Colors.md3.primary : Colors.md3.on_surface
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    QsText {
                        text: `Battery at ${parent.parent.parent.cap}% (${parent.parent.parent.isCharging ? "Charging" : "Discharging"})`
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.md3.on_surface
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }

                    QsText {
                        text: globalBatteryDaemon ? globalBatteryDaemon.timeEstimate : "Battery state healthy"
                        font.pixelSize: 11
                        color: Colors.md3.on_surface_variant
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                }
            }
        }
    }

    // 3. Quick System Launchers
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        QsText { text: "System Diagnostics"; font.pixelSize: 14; font.bold: true; color: Colors.md3.primary }

        Process { id: btopProc; command: ["kitty", "--class", "btop", "-e", "btop"] }
        Process { id: fastfetchProc; command: ["kitty", "--hold", "-e", "fastfetch"] }
        Process { id: autoCpuProc; command: ["auto-cpufreq-gtk"] }

        // 1. Fastfetch (Full System Report)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: 12
            color: Colors.md3.surface_container
            border.color: Colors.md3.outline_variant
            border.width: 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { rootApp.visible = false; fastfetchProc.running = true }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Item {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28
                    QsText { anchors.centerIn: parent; text: "󰣇"; font.pixelSize: 22; color: Colors.md3.primary }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QsText { text: "Full System Report (Fastfetch)"; font.pixelSize: 14; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                    QsText { text: "Display detailed driver, package, resolution, and session info"; font.pixelSize: 11; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                QsText { text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
            }
        }

        // 2. Btop (Task & Hardware Monitor)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: 12
            color: Colors.md3.surface_container
            border.color: Colors.md3.outline_variant
            border.width: 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { rootApp.visible = false; btopProc.running = true }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Item {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28
                    QsText { anchors.centerIn: parent; text: "󰄲"; font.pixelSize: 22; color: Colors.md3.primary }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QsText { text: "Task & Hardware Monitor (Btop)"; font.pixelSize: 14; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                    QsText { text: "Live CPU graphs, process memory, and temperatures"; font.pixelSize: 11; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                QsText { text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
            }
        }

        // 3. auto-cpufreq (CPU Frequency & Governor)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: 12
            color: Colors.md3.surface_container
            border.color: Colors.md3.outline_variant
            border.width: 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { rootApp.visible = false; autoCpuProc.running = true }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Item {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28
                    QsText { anchors.centerIn: parent; text: "󰓅"; font.pixelSize: 22; color: Colors.md3.primary }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QsText { text: "CPU Frequency & Governor (auto-cpufreq)"; font.pixelSize: 14; font.bold: true; color: Colors.md3.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                    QsText { text: "Automatic CPU speed, turbo mode, and battery optimization daemon"; font.pixelSize: 11; color: Colors.md3.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                QsText { text: "󰅂"; font.pixelSize: 16; color: Colors.md3.on_surface_variant }
            }
        }
    }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 20 }
    }
}
