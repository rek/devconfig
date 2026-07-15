// 17 · Boot Log — a scrolling systemd-style status readout, most recent
// line highlighted. Leans on typography and register rather than graphics.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    readonly property var lines: [
        "[    0.812] zmk: split_central: scanning",
        "[    1.004] zmk: bt: " + (root.link === "off" ? "advertising" : "connected " + root.link),
        "[    1.220] battery: left  " + root.lpct + (root.lpct === "--" ? "" : "%"),
        "[    1.221] battery: right " + root.rpct + (root.rpct === "--" ? "" : "%"),
        "[    1.400] hud: poll ok, next in 15s",
    ]

    Rectangle {
        anchors.fill: parent
        anchors.margins: 18
        color: "#050505"
        border.color: "#1e1e1e"
        border.width: 1
        radius: 4

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 18
            spacing: 7
            Repeater {
                model: root.lines
                delegate: Row {
                    spacing: 6
                    Text { text: "OK"; color: "#5dff8a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
                    Text {
                        text: modelData
                        color: index === root.lines.length - 1 ? "#e8fff2" : "#6a6a6a"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
