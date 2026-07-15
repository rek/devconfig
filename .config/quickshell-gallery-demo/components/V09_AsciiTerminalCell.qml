// 09 · Brutalist ASCII — box-drawing border built from text, zero radius,
// blinking cursor block. No decoration beyond the terminal itself.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    property bool blink: true
    Timer { interval: 500; running: true; repeat: true; onTriggered: root.blink = !root.blink }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 20
        color: "#000000"
        border.color: root.accent
        border.width: 1

        Column {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 4

            Text { text: "+--------------------------+"; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            Text { text: "| keeb.status              |"; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            Text { text: "+--------------------------+"; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            Text { text: "  link : " + root.link.padEnd(17, " "); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            Text { text: "  L    : " + root.lpct + (root.lpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            Text { text: "  R    : " + root.rpct + (root.rpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            Row {
                Text { text: "  $ "; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                Rectangle { width: 9; height: 15; color: root.accent; opacity: root.blink ? 1 : 0; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
