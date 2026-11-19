import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: ch
    property string icon: ""
    property string label: ""
    property bool active: false
    property color accent: "#3ec7c0"
    signal clicked()
    implicitHeight: 56
    radius: 16
    border.color: active ? Qt.rgba(accent.r, accent.g, accent.b, 0.65) : Qt.rgba(1, 1, 1, 0.10)
    gradient: Gradient {
        GradientStop { position: 0.0; color: ch.active ? Qt.rgba(ch.accent.r, ch.accent.g, ch.accent.b, 0.42) : Qt.rgba(1, 1, 1, 0.09) }
        GradientStop { position: 1.0; color: ch.active ? Qt.rgba(ch.accent.r, ch.accent.g, ch.accent.b, 0.14) : Qt.rgba(1, 1, 1, 0.03) }
    }
    scale: ma.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    Column {
        anchors.centerIn: parent; spacing: 5
        Kirigami.Icon { anchors.horizontalCenter: parent.horizontalCenter; width: 20; height: 20; source: ch.icon; isMask: true; color: ch.active ? Qt.lighter(ch.accent, 1.3) : Qt.rgba(1, 1, 1, 0.85) }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: ch.label; color: Qt.rgba(1, 1, 1, 0.85); font.family: "Inter Display"; font.pixelSize: 11; font.weight: Font.DemiBold }
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: ch.clicked() }
}
