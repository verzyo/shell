import QtQuick
import QtQuick.Shapes

Item {
    id: root

    enum Corner {
        TopLeft,
        TopRight,
        BottomLeft,
        BottomRight
    }

    property int corner: RoundCorner.Corner.TopLeft
    property int implicitSize: 25
    property color color: "#000000"

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    readonly property bool isTop: corner === RoundCorner.Corner.TopLeft || corner === RoundCorner.Corner.TopRight
    readonly property bool isLeft: corner === RoundCorner.Corner.TopLeft || corner === RoundCorner.Corner.BottomLeft

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            strokeWidth: 0
            fillColor: root.color
            pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting

            startX: root.isLeft ? 0 : root.implicitSize
            startY: root.isTop ? 0 : root.implicitSize

            PathAngleArc {
                moveToStart: false
                centerX: root.implicitSize - shapePath.startX
                centerY: root.implicitSize - shapePath.startY
                radiusX: root.implicitSize
                radiusY: root.implicitSize
                startAngle: switch (root.corner) {
                case RoundCorner.Corner.TopLeft:
                    return 180;
                case RoundCorner.Corner.TopRight:
                    return -90;
                case RoundCorner.Corner.BottomLeft:
                    return 90;
                case RoundCorner.Corner.BottomRight:
                    return 0;
                }
                sweepAngle: 90
            }

            PathLine {
                x: shapePath.startX
                y: shapePath.startY
            }
        }
    }
}
