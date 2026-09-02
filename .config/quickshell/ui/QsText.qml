import QtQuick
import "../globals"
import "../ui"
import "../osd"
import "../quicksettings"

Text {
    font.family: Config.fontName
    font.pixelSize: Config.fontSize
    font.bold: true
    // Grabbing your Matugen on_surface color directly
    color: Colors.md3.on_surface
}
