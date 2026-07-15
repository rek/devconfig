// 08 · Minimalist Glass — frosted rounded panel, hairline border, huge
// light-weight numerals. Restraint as the whole statement.
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Rectangle {
        id: backdrop
        anchors.fill: parent
        anchors.margins: 20
        radius: 24
        color: Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1
    }

    MultiEffect {
        source: backdrop
        anchors.fill: backdrop
        blurEnabled: true
        blur: 0.15
        brightness: 0.05
    }

    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.link === "off" ? "no link" : root.link
            color: Qt.rgba(1, 1, 1, 0.45)
            font.family: "Inter"
            font.pixelSize: 13
            font.letterSpacing: 1
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 36
            Column {
                Text { text: root.lpct === "--" ? "--" : root.lpct; color: "#ffffff"; font.pixelSize: 52; font.weight: Font.Light }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "left"; color: Qt.rgba(1,1,1,0.4); font.pixelSize: 11 }
            }
            Column {
                Text { text: root.rpct === "--" ? "--" : root.rpct; color: "#ffffff"; font.pixelSize: 52; font.weight: Font.Light }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "right"; color: Qt.rgba(1,1,1,0.4); font.pixelSize: 11 }
            }
        }
    }
}
