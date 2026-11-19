import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string sans: "Inter"
    readonly property color ink: "#e6eeeb"
    readonly property color dim: Qt.rgba(0.77, 0.82, 0.80, 0.55)
    readonly property color teal: "#3ec7c0"
    readonly property color amber: "#f5a524"
    readonly property color red: "#e5604d"
    readonly property color green: "#3ddc97"

    Sensors.Sensor { id: cpu;   sensorId: "cpu/all/usage";                updateRateLimit: 2000 }
    Sensors.Sensor { id: cfreq; sensorId: "cpu/all/averageFrequency";     updateRateLimit: 4000 }
    Sensors.Sensor { id: cmax;  sensorId: "cpu/all/maximumTemperature";   updateRateLimit: 4000 }
    Sensors.Sensor { id: ctmp;  sensorId: "cpu/all/averageTemperature";   updateRateLimit: 4000 }
    Sensors.Sensor { id: gpu;   sensorId: "gpu/gpu0/usage";               updateRateLimit: 2000 }
    Sensors.Sensor { id: gtmp;  sensorId: "gpu/gpu0/temperature";         updateRateLimit: 4000 }
    Sensors.Sensor { id: gvu;   sensorId: "gpu/gpu0/usedVram";            updateRateLimit: 4000 }
    Sensors.Sensor { id: gvt;   sensorId: "gpu/gpu0/totalVram";           updateRateLimit: 30000 }
    Sensors.Sensor { id: ram;   sensorId: "memory/physical/usedPercent";  updateRateLimit: 4000 }
    Sensors.Sensor { id: ramu;  sensorId: "memory/physical/used";         updateRateLimit: 4000 }
    Sensors.Sensor { id: ramt;  sensorId: "memory/physical/total";        updateRateLimit: 30000 }
    Sensors.Sensor { id: gpw;   sensorId: "gpu/gpu0/power";               updateRateLimit: 4000 }
    Sensors.Sensor { id: swp;   sensorId: "memory/swap/usedPercent";      updateRateLimit: 10000 }
    Sensors.Sensor { id: drd;   sensorId: "disk/all/read";                updateRateLimit: 4000 }
    Sensors.Sensor { id: dwr;   sensorId: "disk/all/write";               updateRateLimit: 4000 }
    Sensors.Sensor { id: dsk;   sensorId: "disk/all/usedPercent";         updateRateLimit: 30000 }
    Sensors.Sensor { id: dsku;  sensorId: "disk/all/used";                updateRateLimit: 30000 }
    Sensors.Sensor { id: dskt;  sensorId: "disk/all/total";               updateRateLimit: 30000 }
    function rate(b) { b = Number(b); return b > 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : (b > 1024 ? Math.round(b / 1024) + " KB/s" : Math.round(b) + " B/s") }
    function gb(b) { return (Number(b) / 1073741824).toFixed(b > 107374182400 ? 0 : 1) }
    function num(s) { return s && s.value !== undefined ? Number(s.value) : 0 }
    function pad(n, w) { var s = String(Math.round(n)); while (s.length < w) s = "0" + s; return s }
    function zone(t) { return t < 60 ? teal : (t < 80 ? amber : red) }
    function lvl(p) { return p < 20 ? red : (p < 40 ? amber : green) }

    // ---- clock & history ----
    property var now: new Date()
    property var cpuHist: []
    property var gpuHist: []
    property real sCpu: 0
    property real sGpu: 0
    property real sCpuT: 0
    property real sGpuT: 0
    // values shown on screen: only change when the smoothed value moved noticeably (no flicker)
    property real dCpu: 0
    property real dGpu: 0
    property real dCpuT: 0
    property real dGpuT: 0
    property real dFreq: 0
    property real dGpw: 0
    property real sFreq: 0
    property real sGpw: 0
    function ema(prev, v, a) { return prev <= 0 ? v : prev + (v - prev) * a }
    function hy(prev, v, th) { return (prev <= 0 || Math.abs(v - prev) >= th) ? v : prev }
    Component.onCompleted: {
        var a = [], b = []
        for (var i = 0; i < 60; i++) { a.push(0); b.push(0) }
        cpuHist = a; gpuHist = b
    }
    // clock: wake only at minute boundaries
    Timer {
        id: clockT; running: true; repeat: false; interval: 1000
        onTriggered: {
            root.now = new Date()
            interval = 60000 - (root.now.getSeconds() * 1000 + root.now.getMilliseconds()) + 40
            restart()
        }
    }
    // data: every 2 s (sensors are rate-limited too)
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: {
            root.sCpu = root.ema(root.sCpu, root.num(cpu), 0.30)
            root.sGpu = root.ema(root.sGpu, root.num(gpu), 0.30)
            root.sCpuT = root.ema(root.sCpuT, root.num(ctmp), 0.12)
            root.sGpuT = root.ema(root.sGpuT, root.num(gtmp), 0.12)
            root.sFreq = root.ema(root.sFreq, root.num(cfreq) / 1000, 0.20)
            root.sGpw = root.ema(root.sGpw, root.num(gpw), 0.20)
            root.dCpu = root.hy(root.dCpu, root.sCpu, 1.5)
            root.dGpu = root.hy(root.dGpu, root.sGpu, 1.5)
            root.dCpuT = root.hy(root.dCpuT, root.sCpuT, 1.0)
            root.dGpuT = root.hy(root.dGpuT, root.sGpuT, 1.0)
            root.dFreq = root.hy(root.dFreq, root.sFreq, 0.15)
            root.dGpw = root.hy(root.dGpw, root.sGpw, 1.0)
            root.cpuHist = root.cpuHist.concat([root.sCpu]).slice(-60)
            root.gpuHist = root.gpuHist.concat([root.sGpu]).slice(-60)
        }
    }
    // ---- system state ----
    property int vol: 0
    property bool muted: false
    property int bri: 100
    property bool wifiOn: false
    property bool btOn: false
    property string ppd: "balanced"
    property real batPct: 0
    property string batState: ""
    property real batE: 0
    property real batEF: 0
    property real batW: 0
    property real batV: 0
    property real batHealth: 0
    property var devices: []
    property real sBatW: 0
    property var devEma: ({})
    property var devShown: ({})
    readonly property string codeDir: Qt.resolvedUrl("../code/").toString().replace("file://", "")

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
            if (source.indexOf("state.sh") >= 0) root.parseState(data["stdout"] || "")
        }
    }
    function parseState(out) {
        var d = []
        out.split("\n").forEach(function(l) {
            var i = l.indexOf("="); if (i < 0) return
            var k = l.substring(0, i), v = l.substring(i + 1)
            if (k === "vol") vol = parseInt(v) || 0
            else if (k === "mute") muted = v === "1"
            else if (k === "bri") bri = parseInt(v) || 0
            else if (k === "wifi") wifiOn = v === "enabled"
            else if (k === "bt") btOn = v === "yes"
            else if (k === "ppd") ppd = v
            else if (k === "bat") {
                var b = v.split("|")
                batPct = parseFloat(b[0]) || 0; batState = b[1] || ""
                batE = parseFloat(b[2]) || 0; batEF = parseFloat(b[3]) || 0
                batW = parseFloat(b[4]) || 0; batV = parseFloat(b[5]) || 0
                batHealth = parseFloat(b[6]) || 0
                sBatW = root.ema(sBatW, batW, 0.25)
            }
            else if (k === "dev") {
                var p = v.split("|"), raw = parseInt(p[1]) || 0
                devEma[p[0]] = devEma[p[0]] === undefined ? raw : devEma[p[0]] + (raw - devEma[p[0]]) * 0.25
                devShown[p[0]] = (devShown[p[0]] === undefined || Math.abs(devEma[p[0]] - devShown[p[0]]) >= 2) ? Math.round(devEma[p[0]]) : devShown[p[0]]
                d.push({ name: p[0], pct: devShown[p[0]] })
            }
        })
        devices = d
    }
    function poll() { exec.connectSource("sh " + codeDir + "state.sh") }
    function ctl(args) { exec.connectSource("sh " + codeDir + "ctl.sh " + args); pollSoon.restart() }
    Timer { id: pollSoon; interval: 700; onTriggered: root.poll() }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.poll() }

    function shortName(n) { return n.replace(/^(Logitech|Lenovo|Razer|Microsoft|Apple|HP|Dell)\s*/i, "") }
    readonly property bool charging: batState === "charging" || batState === "pending-charge"

    readonly property string ppdLabel: ppd === "power-saver" ? "Tasarruf" : (ppd === "performance" ? "Performans" : "Dengeli")
    readonly property string ppdIcon: ppd === "power-saver" ? "power-profile-power-saver-symbolic" : (ppd === "performance" ? "power-profile-performance-symbolic" : "power-profile-balanced-symbolic")

    function etaText() {
        if (sBatW < 0.5) return ""
        var h = charging ? (batEF - batE) / sBatW : batE / sBatW
        if (!isFinite(h) || h < 0) return ""
        var mins = Math.max(5, Math.round(h * 12) * 5)      // 5-minute steps: no jitter
        return (charging ? "Dolmasına ≈ " : "Bitmesine ≈ ") + Math.floor(mins / 60) + " sa " + (mins % 60 < 10 ? "0" : "") + (mins % 60) + " dk"
    }
    readonly property real dayFrac: (now.getHours() * 3600 + now.getMinutes() * 60) / 86400
    readonly property color blue: "#6aa7ff"
    readonly property color violet: "#b69cff"
    function digit(c) { return c }

    fullRepresentation: Item {
        implicitWidth: 772
        implicitHeight: Math.max(left.implicitHeight, right.implicitHeight)
        Layout.minimumWidth: 772
        Layout.minimumHeight: Math.max(left.implicitHeight, right.implicitHeight)

        RowLayout {
            anchors.fill: parent
            spacing: 12

            // ================= SOL =================
            ColumnLayout {
                id: left
                Layout.preferredWidth: 380; Layout.maximumWidth: 380; Layout.alignment: Qt.AlignTop
                spacing: 12

                // ----- Saat & tarih -----
                GCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 158
                    accent: root.blue
                    Item {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 22; width: wd.implicitWidth + 24; radius: 11
                                color: Qt.rgba(0.416, 0.655, 1, 0.20); border.color: Qt.rgba(0.416, 0.655, 1, 0.45)
                                Text { id: wd; anchors.centerIn: parent
                                    text: Qt.locale("tr_TR").toString(root.now, "dddd").toUpperCase()
                                    color: "#bcd6ff"; font.family: "Inter Display"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 2.5 }
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                Repeater {
                                    model: Qt.formatTime(root.now, "HH:mm").split("")
                                    delegate: Item {
                                        width: modelData === ":" ? 26 : 56; height: 84
                                        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: modelData === ":" ? -5 : 0
                                            text: modelData; color: modelData === ":" ? root.blue : "white"
                                            font.family: "Inter Display"; font.pixelSize: 92; font.weight: Font.DemiBold }
                                    }
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.locale("tr_TR").toString(root.now, "d MMMM yyyy")
                                color: Qt.rgba(1, 1, 1, 0.70); font.family: "Inter Display"; font.pixelSize: 14; font.weight: Font.Medium
                            }
                        }
                    }
                }

                // ----- Pil -----
                GCard {
                    Layout.fillWidth: true; Layout.preferredHeight: implicitHeight; Layout.fillHeight: true
                    title: "Pil"; icon: root.charging ? "battery-full-charging-symbolic" : "battery-good-symbolic"; accent: root.lvl(root.batPct)
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 14
                        Item { Layout.fillWidth: true }
                        BatteryCap { value: root.batPct; fillColor: root.lvl(root.batPct); charging: root.charging }
                        ColumnLayout {
                            Layout.fillWidth: false; spacing: 1
                            RowLayout {
                                spacing: 8
                                Text { text: Math.round(root.batPct) + "%"; color: root.lvl(root.batPct); font.family: "Inter Display"; font.pixelSize: 40; font.weight: Font.DemiBold }
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    height: 20; width: bst.implicitWidth + 16; radius: 10
                                    color: Qt.rgba(root.lvl(root.batPct).r, root.lvl(root.batPct).g, root.lvl(root.batPct).b, 0.20)
                                    border.color: Qt.rgba(root.lvl(root.batPct).r, root.lvl(root.batPct).g, root.lvl(root.batPct).b, 0.45)
                                    Text { id: bst; anchors.centerIn: parent
                                        text: root.charging ? "Şarjda" : (root.batState === "fully-charged" ? "Dolu" : "Pilde")
                                        color: root.lvl(root.batPct); font.family: "Inter Display"; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                            }
                            Text { text: root.etaText(); visible: text !== ""; color: Qt.rgba(1, 1, 1, 0.62); font.family: "Inter Display"; font.pixelSize: 13 }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter; spacing: 8; visible: root.devices.length > 0
                        Repeater {
                            model: root.devices
                            delegate: Rectangle {
                                height: 28; radius: 14; width: pill.implicitWidth + 22
                                color: Qt.rgba(1, 1, 1, 0.08); border.color: Qt.rgba(1, 1, 1, 0.10)
                                Row {
                                    id: pill; anchors.centerIn: parent; spacing: 6
                                    Kirigami.Icon { anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; source: "input-mouse-symbolic"; isMask: true; color: root.lvl(modelData.pct) }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: root.shortName(modelData.name); color: Qt.rgba(1, 1, 1, 0.8); font.family: "Inter Display"; font.pixelSize: 12 }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.pct + "%"; color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // ----- Kontrol -----
                GCard {
                    Layout.fillWidth: true; Layout.preferredHeight: implicitHeight; Layout.fillHeight: true
                    title: "Kontrol"; icon: "preferences-system-power-symbolic"; accent: root.teal
                    Item { Layout.fillHeight: true }
                    PillSlider { Layout.fillWidth: true; value: root.vol; icon: root.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"; accent: root.muted ? root.red : "#3ec7c0"; valueText: root.vol + "%"; onCommit: (v) => root.ctl("vol " + v) }
                    PillSlider { Layout.fillWidth: true; value: root.bri; icon: "display-brightness-symbolic"; accent: "#f5a524"; valueText: root.bri + "%"; onCommit: (v) => { root.bri = v; root.ctl("bri " + v) } }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        IconChip { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "network-wireless-symbolic"; label: "Wi-Fi"; accent: "#6aa7ff"; active: root.wifiOn; onClicked: root.ctl("wifi") }
                        IconChip { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "bluetooth-symbolic"; label: "Bluetooth"; accent: "#6aa7ff"; active: root.btOn; onClicked: root.ctl("bt") }
                        IconChip { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "audio-volume-muted-symbolic"; label: "Sessiz"; accent: root.red; active: root.muted; onClicked: root.ctl("mute") }
                        IconChip { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: root.ppdIcon; label: root.ppdLabel; active: root.ppd !== "balanced"; accent: root.ppd === "performance" ? root.red : root.green; onClicked: root.ctl("ppd") }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // ================= SAĞ =================
            ColumnLayout {
                id: right
                Layout.preferredWidth: 380; Layout.maximumWidth: 380; Layout.fillHeight: true
                spacing: 12

                GCard {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    title: "Sistem"; icon: "utilities-system-monitor-symbolic"; accent: root.blue
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Row { spacing: 5; Rectangle { width: 8; height: 8; radius: 4; color: root.blue; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "CPU"; color: Qt.rgba(1, 1, 1, 0.7); font.family: "Inter Display"; font.pixelSize: 12 } }
                        Row { spacing: 5; Rectangle { width: 8; height: 8; radius: 4; color: root.green; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "GPU"; color: Qt.rgba(1, 1, 1, 0.7); font.family: "Inter Display"; font.pixelSize: 12 } }
                        Item { Layout.fillWidth: true }
                        Text { text: "son 2 dk"; color: Qt.rgba(1, 1, 1, 0.4); font.family: "Inter Display"; font.pixelSize: 11 }
                    }
                    Spark { Layout.fillWidth: true; Layout.preferredHeight: 44; samples: root.cpuHist; samples2: root.gpuHist; accent: root.blue; accent2: root.green }
                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 8; rowSpacing: 8
                        Tile {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            icon: "cpu-symbolic"; label: "İşlemci"; accent: root.blue
                            value: root.dCpu; valueText: Math.round(root.dCpu) + ""
                            detail: Math.round(root.dCpuT) + "°C · " + root.dFreq.toFixed(1) + " GHz"
                            detailColor: root.zone(root.dCpuT)
                        }
                        Tile {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            icon: "video-display-symbolic"; label: "Ekran kartı"; accent: root.green
                            value: root.dGpu; valueText: Math.round(root.dGpu) + ""
                            detail: Math.round(root.dGpuT) + "°C · " + root.gb(root.num(gvu)) + "/" + root.gb(root.num(gvt)) + " GB"
                            detailColor: root.zone(root.dGpuT)
                        }
                        Tile {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            icon: "drive-harddisk-symbolic"; label: "Bellek"; accent: root.violet
                            value: root.num(ram)
                            detail: root.gb(root.num(ramu)) + " / " + root.gb(root.num(ramt)) + " GB"
                        }
                        Tile {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            icon: "drive-harddisk-symbolic"; label: "Depolama"; accent: root.amber
                            value: root.num(dsk)
                            detail: root.gb(root.num(dsku)) + " / " + root.gb(root.num(dskt)) + " GB"
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "GPU gücü"; color: Qt.rgba(1, 1, 1, 0.55); font.family: "Inter Display"; font.pixelSize: 12 }
                        Text { text: root.dGpw.toFixed(0) + " W"; color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: "Takas"; color: Qt.rgba(1, 1, 1, 0.55); font.family: "Inter Display"; font.pixelSize: 12 }
                        Text { text: Math.round(root.num(swp)) + "%"; color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Bold }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1, 1, 1, 0.08) }
                    RowLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 90; Layout.maximumHeight: 124; spacing: 10
                        Repeater {
                            model: [ { n: "İşlemci", t: root.dCpuT }, { n: "Ekran kartı", t: root.dGpuT } ]
                            delegate: ArcGauge { Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.preferredHeight: 90; temp: modelData.t; label: modelData.n }
                        }
                    }
                }
            }
        }
    }
}
