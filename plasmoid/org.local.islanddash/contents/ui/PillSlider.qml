import QtQuick
import org.kde.kirigami as Kirigami

// Thick pill slider: gradient fill, icon inside, value on the right
Item {
    id: s
    property real value: 0
    property string icon: ""
    property color accent: "#3ec7c0"
    property string valueText: ""
    signal commit(int v)
    implicitHeight: 36
    Rectangle {
        id: track
        anchors.fill: parent; radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.08); border.color: Qt.rgba(1, 1, 1, 0.08)
        Rectangle {
            width: Math.max(parent.height, parent.width * s.value / 100); height: parent.height; radius: parent.radius
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.darker(s.accent, 1.35) } GradientStop { position: 1.0; color: Qt.lighter(s.accent, 1.1) } }
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }
        Kirigami.Icon { x: 11; anchors.verticalCenter: parent.verticalCenter; width: 17; height: 17; source: s.icon; isMask: true; color: "white" }
        Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: s.valueText
            color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Bold }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        function set(x) { s.value = Math.max(0, Math.min(100, x / width * 100)) }
        onPressed: (m) => set(m.x)
        onPositionChanged: (m) => { if (pressed) set(m.x) }
        onReleased: s.commit(Math.round(s.value))
    }
}
