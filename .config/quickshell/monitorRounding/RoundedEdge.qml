import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property int corner: 0 // 0: TopLeft, 1: TopRight, 2: BottomLeft, 3: BottomRight
    property color fillColor: "#000000"
    property int cornerSize: 16

    implicitWidth: cornerSize
    implicitHeight: cornerSize

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: sp
            strokeWidth: 0
            fillColor: root.fillColor
            pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting

            startX: root.corner % 2 == 1 ? root.cornerSize : 0
            startY: root.corner < 2 ? 0 : root.cornerSize

            PathAngleArc {
                moveToStart: false
                centerX: root.cornerSize - sp.startX
                centerY: root.cornerSize - sp.startY
                radiusX: root.cornerSize
                radiusY: root.cornerSize
                startAngle: root.corner == 0 ? 180 : (root.corner == 1 ? -90 : (root.corner == 2 ? 90 : 0))
                sweepAngle: 90
            }

            PathLine {
                x: sp.startX
                y: sp.startY
            }
        }
    }
}
