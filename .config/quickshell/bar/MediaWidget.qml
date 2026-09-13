import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Mpris
import "../globals"
import "../ui"

Pill {
    id: root
    clickable: true
    paddingHorizontal: 14

    readonly property var activeMedia: (typeof globalMediaCenter !== "undefined" && globalMediaCenter) ? globalMediaCenter.player : null

    onClicked: (mouse) => {
        if (typeof globalMediaCenter !== "undefined" && globalMediaCenter) globalMediaCenter.toggle()
    }

    onRightClicked: (mouse) => {
        if (root.activeMedia) root.activeMedia.togglePlaying()
    }

    onMiddleClicked: (mouse) => {
        if (root.activeMedia) root.activeMedia.next()
    }

    onWheelScrolled: (wheel) => {
        if (root.activeMedia && root.activeMedia.canControl) {
            let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.activeMedia.volume = Math.max(0.0, Math.min(1.0, root.activeMedia.volume + delta))
        }
    }

    // Smart cleaning & prioritization of media metadata (especially YouTube / Chrome)
    function getDisplayMediaText(player) {
        if (!player) return "Music";

        let title = (player.trackTitle || "").trim();
        let artist = (player.trackArtist || "").trim();

        // 1. Strip YouTube web page title suffixes
        title = title.replace(/\s*[-–—|]\s*YouTube$/i, "").trim();

        // 2. Clean YouTube Music "- Topic" suffixes from artist
        artist = artist.replace(/\s*[-–—]\s*Topic$/i, "").trim();

        // 3. Filter out generic browser / platform names as artists
        if (/^(youtube|google chrome|chromium|web browser)$/i.test(artist)) {
            artist = "";
        }

        // 4. Fallback if title is missing
        if (!title) {
            return artist || "Playing";
        }

        // 5. If no artist, or if title already contains the artist (e.g. "Artist - Song")
        if (!artist) {
            return title;
        }

        let lowerTitle = title.toLowerCase();
        let lowerArtist = artist.toLowerCase();
        if (lowerTitle.startsWith(lowerArtist) || lowerTitle.includes(" - " + lowerArtist) || lowerTitle.includes(lowerArtist + " - ")) {
            return title;
        }

        // 6. Title is ALWAYS prioritized first so video/song names are never cut off
        return `${title} • ${artist}`;
    }

    RowLayout {
        spacing: 8

        QsText {
            text: root.activeMedia && root.activeMedia.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
            color: Colors.md3.primary
            font.pixelSize: 14
        }

        Item {
            Layout.preferredWidth: trackText.implicitWidth
            implicitHeight: trackText.implicitHeight
            clip: true

            QsText {
                id: trackText
                text: root.getDisplayMediaText(root.activeMedia)
                font.italic: !root.activeMedia
                elide: Text.ElideRight
            }
        }
    }
}
