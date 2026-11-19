import QtQuick
import QtQuick.Shapes

Item {
    id: ring
    property real value: 0
    property color accent: "#3ddc97"
    property int size: 84
    property int thick: 9
    property alias text: lbl.text
    implicitWidth: size; implicitHeight: size
    Shape {
        anchors.fill: parent
        layer.enabled: true; layer.samples: 8
        ShapePath {
            strokeColor: Qt.rgba(1, 1, 1, 0.12); strokeWidth: ring.thick
            fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: ring.size/2; centerY: ring.size/2; radiusX: ring.size/2 - ring.thick/2 - 1; radiusY: ring.size/2 - ring.thick/2 - 1; startAngle: -90; sweepAngle: 359.9 }
        }
        ShapePath {
            strokeColor: ring.accent; strokeWidth: ring.thick
            fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.size/2; centerY: ring.size/2; radiusX: ring.size/2 - ring.thick/2 - 1; radiusY: ring.size/2 - ring.thick/2 - 1; startAngle: -90
                sweepAngle: Math.max(0.1, Math.min(100, ring.value)) * 3.599
                Behavior on sweepAngle { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
            }
        }
    }
    Text {
        id: lbl
        anchors.centerIn: parent
        color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: ring.size * 0.30; font.weight: Font.Bold
    }
}
