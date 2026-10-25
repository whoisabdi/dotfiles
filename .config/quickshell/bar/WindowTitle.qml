import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../globals"
import "../ui"

Pill {
    id: root
    paddingHorizontal: 14
    clickable: true

    readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property bool hasActiveWindow: activeToplevel && activeToplevel.activated && activeToplevel.title.length > 0

    readonly property string appIconName: {
        if (!activeToplevel) return ""
        let entry = DesktopEntries.heuristicLookup(activeToplevel.appId)
        return (entry && entry.icon) ? entry.icon : activeToplevel.appId
    }

    readonly property string fallbackMedia: {
        if (typeof globalMediaCenter !== "undefined" && globalMediaCenter && globalMediaCenter.player) {
            let p = globalMediaCenter.player
            if (p.trackTitle && p.trackTitle.trim().length > 0) {
                return (p.trackArtist ? `${p.trackArtist} - ` : "") + p.trackTitle
            }
        }
        return ""
    }

    readonly property string displayTitle: {
        if (hasActiveWindow) return activeToplevel.title
        if (fallbackMedia.length > 0) return fallbackMedia
        return `Workspace ${monitor?.activeWorkspace?.id ?? 1}`
    }

    onClicked: {
        if (hasActiveWindow && typeof activeToplevel.activate === "function") {
            activeToplevel.activate()
        }
    }

    RowLayout {
        spacing: 8

        // Icon: App Icon if window focused, music note if fallback media, or Arch icon
        Item {
            implicitWidth: 16
            implicitHeight: 16
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                visible: root.hasActiveWindow && root.appIconName !== ""
                source: root.hasActiveWindow ? Quickshell.iconPath(root.appIconName, "application-x-executable") : ""
            }

            QsText {
                anchors.centerIn: parent
                visible: !root.hasActiveWindow || root.appIconName === ""
                text: root.fallbackMedia.length > 0 ? "󰝚" : "󰣇"
                color: Colors.md3.primary
                font.pixelSize: 13
            }
        }

        Item {
            Layout.preferredWidth: Math.min(240, titleText.implicitWidth)
            implicitHeight: titleText.implicitHeight
            clip: true

            QsText {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayTitle
                font.bold: root.hasActiveWindow
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }
}
