import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../globals"
import "../ui"

PanelWindow {
    id: window
    WlrLayershell.namespace: "mediacenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: false

    function toggle() { 
        visible = !visible 
        if (visible) bgMouse.forceActiveFocus()
    }

    property var players: Mpris.players.values
    property int currentIndex: 0
    property var player: players.length > 0 ? players[Math.min(currentIndex, Math.max(0, players.length - 1))] : null

    function getArtUrl(p) {
        if (!p) return "";
        let url = p.trackArtUrl || p.artUrl || (p.metadata ? (p.metadata["mpris:artUrl"] || p.metadata.artUrl) : "");
        if (!url) return "";
        let s = url.toString().trim();
        if (!s) return "";
        if (s.startsWith("https://open.spotify.com/image/")) {
            return s.replace("https://open.spotify.com/image/", "https://i.scdn.co/image/");
        }
        if (s.startsWith("http://open.spotify.com/image/")) {
            return s.replace("http://open.spotify.com/image/", "https://i.scdn.co/image/");
        }
        if (s.startsWith("/")) {
            return "file://" + s;
        }
        return s;
    }

    function cleanTitle(p) {
        if (!p || !p.trackTitle) return "No Media Playing";
        return p.trackTitle.trim().replace(/\s*[-–—|]\s*YouTube$/i, "").trim();
    }

    function cleanArtist(p) {
        if (!p || !p.trackArtist) return "";
        let a = p.trackArtist.trim().replace(/\s*[-–—]\s*Topic$/i, "").trim();
        if (/^(youtube|google chrome|chromium|web browser)$/i.test(a)) return "";
        return a;
    }

    MouseArea {
        id: bgMouse
        anchors.fill: parent
        onClicked: window.visible = false
        Keys.onEscapePressed: window.visible = false
    }

    Rectangle {
        width: 460
        height: 180
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter

        radius: 20
        color: Colors.md3.surface_container_high
        border.color: Colors.md3.outline_variant
        border.width: 1
        clip: true

        MouseArea { anchors.fill: parent }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 20

            // Album Cover Card (True Rounded Corners)
            Item {
                Layout.preferredWidth: 144
                Layout.preferredHeight: 144

                // Background container & fallback icon
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Colors.md3.surface_variant

                    QsText {
                        anchors.centerIn: parent
                        text: "󰝚"
                        font.pixelSize: 48
                        color: Colors.md3.on_surface_variant
                    }
                }

                // Rounded Canvas Renderer
                Canvas {
                    id: artCanvas
                    anchors.fill: parent
                    readonly property string artSource: window.player ? window.getArtUrl(window.player) : ""

                    onArtSourceChanged: {
                        if (artSource && artSource.length > 0) {
                            loadImage(artSource);
                        }
                        requestPaint();
                    }

                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.reset();
                        let w = width, h = height, r = 14;
                        if (w <= 0 || h <= 0) return;

                        if (artSource && isImageLoaded(artSource)) {
                            ctx.beginPath();
                            ctx.moveTo(r, 0);
                            ctx.lineTo(w - r, 0);
                            ctx.arcTo(w, 0, w, r, r);
                            ctx.lineTo(w, h - r);
                            ctx.arcTo(w, h, w - r, h, r);
                            ctx.lineTo(r, h);
                            ctx.arcTo(0, h, 0, h - r, r);
                            ctx.lineTo(0, r);
                            ctx.arcTo(0, 0, r, 0, r);
                            ctx.closePath();
                            ctx.clip();
                            ctx.drawImage(artSource, 0, 0, w, h);
                        }
                    }

                    onImageLoaded: requestPaint()
                }
            }

            // Right Info & Controls Column
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Header Row (Player Identity & Switcher)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    QsText {
                        text: window.player ? window.player.identity : "Media"
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.md3.primary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 6
                        visible: window.players.length > 1
                        Repeater {
                            model: window.players.length
                            delegate: Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: index === window.currentIndex ? Colors.md3.primary : Colors.md3.outline_variant
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.currentIndex = index
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Title & Artist Info (Centered)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3

                    QsText {
                        text: window.player ? window.cleanTitle(window.player) : "No Media Playing"
                        font.pixelSize: 16
                        font.bold: true
                        color: Colors.md3.on_surface
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }

                    QsText {
                        text: window.player ? window.cleanArtist(window.player) : ""
                        font.pixelSize: 13
                        color: Colors.md3.on_surface_variant
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        visible: text.length > 0
                    }
                }

                Item { Layout.fillHeight: true }

                // Playback Controls Row (Centered)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    // Previous Button
                    MouseArea {
                        implicitWidth: 34; implicitHeight: 34
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: if (window.player) window.player.previous()

                        QsText {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.pixelSize: 22
                            color: parent.containsMouse ? Colors.md3.primary : Colors.md3.on_surface
                        }
                    }

                    // Play/Pause Button
                    Rectangle {
                        implicitWidth: 46; implicitHeight: 46
                        radius: 23
                        color: Colors.md3.primary
                        scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.06 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: if (window.player) window.player.togglePlaying()

                            QsText {
                                anchors.centerIn: parent
                                text: window.player && window.player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                font.pixelSize: 26
                                color: Colors.md3.on_primary
                            }
                        }
                    }

                    // Next Button
                    MouseArea {
                        implicitWidth: 34; implicitHeight: 34
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: if (window.player) window.player.next()

                        QsText {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.pixelSize: 22
                            color: parent.containsMouse ? Colors.md3.primary : Colors.md3.on_surface
                        }
                    }
                }

                Item { Layout.preferredHeight: 4 }
            }
        }
    }
}
