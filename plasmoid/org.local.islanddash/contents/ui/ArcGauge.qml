import QtQuick

// Half-circle temperature gauge, 20..100 C, teal / amber / red zones
Item {
    id: g
    property real temp: 20
    property string label: ""
    readonly property color zoneColor: temp < 60 ? "#3ec7c0" : (temp < 80 ? "#f5a524" : "#e5604d")
    function frac(t) { return Math.max(0, Math.min(1, (t - 20) / 80)) }
    onTempChanged: cv.requestPaint()
    implicitHeight: 96

    Canvas {
        id: cv
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var w = width, h = height, cx = w / 2, r = Math.min(w / 2 - 12, h - 26), cy = h - 16, lw = 9
            function arc(f0, f1, col, cap) {
                ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI * (1 + f0), Math.PI * (1 + f1), false)
                ctx.lineWidth = lw; ctx.lineCap = cap; ctx.strokeStyle = col; ctx.stroke()
            }
            // zone track (dim)
            arc(0.000, 0.485, "rgba(62,199,192,0.28)", "butt")
            arc(0.505, 0.735, "rgba(245,165,36,0.26)", "butt")
            arc(0.755, 1.000, "rgba(229,96,77,0.30)", "butt")
            // value arc
            var f = g.frac(g.temp)
            if (f > 0.02) arc(0, f, g.zoneColor, "round")
            // marker
            var a = Math.PI * (1 + f)
            ctx.beginPath(); ctx.arc(cx + r * Math.cos(a), cy + r * Math.sin(a), 5.5, 0, 2 * Math.PI)
            ctx.fillStyle = "white"; ctx.fill()
            ctx.lineWidth = 1; ctx.strokeStyle = "rgba(0,0,0,0.35)"; ctx.stroke()
        }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 62
        spacing: 2
        Text { text: Math.round(g.temp); color: g.zoneColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; font.weight: Font.Bold }
        Text { text: "°C"; color: Qt.rgba(1, 1, 1, 0.5); font.family: "Inter"; font.pixelSize: 12; topPadding: 9 }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 20
        text: g.label; color: Qt.rgba(1, 1, 1, 0.65); font.family: "Inter"; font.pixelSize: 12; font.weight: Font.Medium
    }
}
