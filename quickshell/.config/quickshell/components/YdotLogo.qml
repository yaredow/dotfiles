import QtQuick
import qs.config

Canvas {
    id: root

    implicitWidth: 20
    implicitHeight: 20

    property color strokeColor: Config.textColor
    property color dotColor: Config.accentColor

    onStrokeColorChanged: requestPaint()
    onDotColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    renderStrategy: Canvas.Cooperative

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var s = Math.min(width, height) / 100

        ctx.strokeStyle = strokeColor
        ctx.lineWidth = 13 * s
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        ctx.beginPath()
        ctx.moveTo(27 * s, 17 * s)
        ctx.lineTo(50 * s, 48 * s)
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(50 * s, 48 * s)
        ctx.lineTo(50 * s, 83 * s)
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(50 * s, 48 * s)
        ctx.lineTo(60 * s, 33 * s)
        ctx.stroke()

        ctx.fillStyle = dotColor
        ctx.beginPath()
        ctx.arc(76 * s, 16 * s, 11 * s, 0, 2 * Math.PI)
        ctx.fill()
    }
}
