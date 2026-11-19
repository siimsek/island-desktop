import QtQuick

// Smooth dual-series area chart (history 0..100)
Canvas {
    id: sp
    property var samples: []
    property var samples2: []
    property color accent: "#6aa7ff"
    property color accent2: "#3ddc97"
    onSamplesChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        var w = width, h = height, n = 60, step = w / (n - 1)
        var peak = 30
        for (var q = 0; q < (samples || []).length; q++) peak = Math.max(peak, samples[q])
        for (var r = 0; r < (samples2 || []).length; r++) peak = Math.max(peak, samples2[r])
        peak = Math.min(100, peak * 1.25)
        // faint horizontal guides
        ctx.strokeStyle = "rgba(255,255,255,0.07)"; ctx.lineWidth = 1
        for (var g = 1; g < 4; g++) { var gy = Math.round(h * g / 4) + 0.5; ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke() }
        function series(s, col, fillA) {
            if (!s || s.length < 2) return
            var off = n - s.length
            function X(i) { return (off + i) * step }
            function Y(v) { return h - 3 - (Math.max(0, Math.min(peak, v)) / peak) * (h - 8) }
            function path() {
                ctx.beginPath(); ctx.moveTo(X(0), Y(s[0]))
                for (var i = 1; i < s.length; i++) {
                    var mx = (X(i - 1) + X(i)) / 2, my = (Y(s[i - 1]) + Y(s[i])) / 2
                    ctx.quadraticCurveTo(X(i - 1), Y(s[i - 1]), mx, my)
                }
                ctx.lineTo(X(s.length - 1), Y(s[s.length - 1]))
            }
            path(); ctx.lineTo(X(s.length - 1), h); ctx.lineTo(X(0), h); ctx.closePath()
            var gr = ctx.createLinearGradient(0, 0, 0, h)
            gr.addColorStop(0, Qt.rgba(col.r, col.g, col.b, fillA)); gr.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0))
            ctx.fillStyle = gr; ctx.fill()
            path(); ctx.lineJoin = "round"; ctx.lineCap = "round"; ctx.strokeStyle = col; ctx.lineWidth = 2; ctx.stroke()
        }
        series(samples2, accent2, 0.18)
        series(samples, accent, 0.32)
    }
}
