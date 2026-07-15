// 23 · Binary Pulse — a ticker of scrolling 1s and 0s standing in for the
// raw link data stream; density of 1s nods at signal strength.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    function bitStream(density, len) {
        let s = "";
        for (let i = 0; i < len; i++) s += (Math.sin(i * 12.9898 + density * 78.233) * 43758.5453 % 1 > (1 - density)) ? "1" : "0";
        return s;
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 16
        color: "#050806"
        radius: 6
        clip: true

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width - 20

            Repeater {
                model: 4
                delegate: Text {
                    text: root.bitStream(root.link === "off" ? 0.15 : 0.6, 48)
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.9 - index * 0.18)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    elide: Text.ElideNone
                    width: parent.width
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 10
            spacing: 20
            Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: "#e8fff2"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
            Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: "#e8fff2"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
        }
    }
}
