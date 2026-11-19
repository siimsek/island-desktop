import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Frosted glass card with an icon badge header
Rectangle {
    id: c
    property string title: ""
    property string icon: ""
    property color accent: "#3ec7c0"
    default property alias content: body.data
    readonly property real bodyTop: title !== "" ? 46 : 16
    implicitHeight: body.implicitHeight + bodyTop + 16
    radius: 24
    color: Qt.rgba(0.07, 0.10, 0.16, 0.52)
    border.color: Qt.rgba(1, 1, 1, 0.14)
    border.width: 1

    Rectangle {                // frosted sheen + accent tint
        anchors.fill: parent; radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.02) }
            GradientStop { position: 1.0; color: Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.07) }
        }
    }
    Rectangle { x: c.radius; y: 1; width: parent.width - c.radius * 2; height: 1; color: Qt.rgba(1, 1, 1, 0.30) }
    Row {
        visible: c.title !== ""
        x: 16; y: 12; spacing: 8
        Rectangle {
            width: 24; height: 24; radius: 8
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.34) }
                GradientStop { position: 1.0; color: Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.14) }
            }
            Kirigami.Icon { anchors.centerIn: parent; width: 15; height: 15; source: c.icon; isMask: true; color: c.accent }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: c.title; color: Qt.rgba(1, 1, 1, 0.90)
            font.family: "Inter Display"; font.pixelSize: 15; font.weight: Font.DemiBold
        }
    }
    ColumnLayout {
        id: body
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.topMargin: c.bodyTop; anchors.bottomMargin: 16
        spacing: 8
    }
}
