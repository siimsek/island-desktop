import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Metric tile: icon + label, big value, bar, detail line
Rectangle {
    id: t
    property string icon: ""
    property string label: ""
    property real value: 0           // 0..100
    property string valueText: Math.round(value) + ""
    property string unit: "%"
    property string detail: ""
    property color accent: "#6aa7ff"
    property color detailColor: Qt.rgba(1, 1, 1, 0.62)
    implicitHeight: 82
    radius: 18
    border.color: Qt.rgba(t.accent.r, t.accent.g, t.accent.b, 0.20)
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(t.accent.r, t.accent.g, t.accent.b, 0.13) }
        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
    }
    Row {
        x: 12; y: 9; spacing: 6
        Kirigami.Icon { anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; source: t.icon; isMask: true; color: t.accent }
        Text { anchors.verticalCenter: parent.verticalCenter; text: t.label; color: Qt.rgba(1, 1, 1, 0.78); font.family: "Inter Display"; font.pixelSize: 12; font.weight: Font.DemiBold }
    }
    Row {
        x: 12; y: 22; spacing: 2
        Text { text: t.valueText; color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 27; font.weight: Font.Bold }
        Text { text: t.unit; color: Qt.rgba(1, 1, 1, 0.5); font.family: "Inter"; font.pixelSize: 12; topPadding: 10 }
    }
    Rectangle {
        x: 12; y: 57; width: parent.width - 24; height: 4; radius: 2; color: Qt.rgba(1, 1, 1, 0.10)
        Rectangle {
            width: Math.max(4, parent.width * Math.min(100, t.value) / 100); height: parent.height; radius: 2
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.darker(t.accent, 1.5) } GradientStop { position: 1.0; color: t.accent } }
            Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        }
    }
    Text {
        x: 12; y: 64; width: parent.width - 24
        text: t.detail; elide: Text.ElideRight
        color: t.detailColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
    }
}
