// 04 · LCD Digit — calculator-style readout: dim "88" ghost segments behind
// the live percentage, plus a faint scanline overlay.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 18
        color: "#04140a"
        border.color: Qt.darker(root.accent, 1.4)
        border.width: 2
        radius: 4

        Column {
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: [ { tag: "L", pct: root.lpct }, { tag: "R", pct: root.rpct } ]
                delegate: Item {
                    width: 220; height: 60
                    Text {
                        anchors.centerIn: parent
                        text: "88"
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 46
                        font.bold: true
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.tag + (modelData.pct === "--" ? " --" : (" " + modelData.pct + "%"))
                        color: root.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 32
                        font.bold: true
                    }
                }
            }
        }

        Column {
            anchors.fill: parent
            spacing: 3
            Repeater {
                model: Math.floor(parent.height / 4)
                delegate: Rectangle { width: parent.width; height: 1; color: "#000000"; opacity: 0.15 }
            }
        }

        Text {
            anchors.top: parent.top; anchors.right: parent.right
            anchors.margins: 8
            text: root.link.toUpperCase()
            color: root.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            opacity: 0.8
        }
    }
}
