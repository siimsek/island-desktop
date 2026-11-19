import QtQuick
import org.kde.kirigami as Kirigami

// Battery capsule: gradient fill, gloss, bolt when charging
Item {
    id: b
    property real value: 0
    property color fillColor: "#3ddc97"
    property bool charging: false
    implicitWidth: 130; implicitHeight: 52
    Rectangle {
        id: shell
        width: 120; height: 52; radius: 16
        color: Qt.rgba(1, 1, 1, 0.05)
        border.color: Qt.rgba(1, 1, 1, 0.34); border.width: 2
        Rectangle {
            id: fill
            x: 4; y: 4; height: parent.height - 8
            width: Math.max(12, (parent.width - 8) * Math.min(100, b.value) / 100)
            radius: 12
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.darker(b.fillColor, 1.5) }
                GradientStop { position: 1.0; color: Qt.lighter(b.fillColor, 1.12) }
            }
            Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
            Rectangle {      // gloss
                x: 3; y: 3; width: parent.width - 6; height: parent.height * 0.40; radius: 9
                color: Qt.rgba(1, 1, 1, 0.20)
            }
        }
        Kirigami.Icon { visible: b.charging; anchors.centerIn: parent; width: 22; height: 22; source: "battery-full-charging-symbolic"; isMask: true; color: "white" }
    }
    Rectangle { x: 122; anchors.verticalCenter: shell.verticalCenter; width: 7; height: 20; radius: 3; color: Qt.rgba(1, 1, 1, 0.34) }
}
