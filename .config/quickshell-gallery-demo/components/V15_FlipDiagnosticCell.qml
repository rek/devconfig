// 15 · Flip Diagnostic — reuses the existing FlipCard primitive: front is the
// glance view, back reveals raw diagnostics. Click or drag to turn it over.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    FlipCard {
        anchors.centerIn: parent
        cardWidth: root.width - 40
        cardHeight: root.height - 40
        borderColor: root.accent
        background: "#b8070b08"

        front: [
            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.link === "usb" ? "󰈷 USB" : root.link === "ble" ? "󰂯 BLE" : "󰌐 OFF"
                    color: root.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 26; font.bold: true }
                    Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 26; font.bold: true }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "click or drag for detail"
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }
        ]

        back: [
            Column {
                anchors.centerIn: parent
                spacing: 4
                Text { text: "mac  E8:0C:B3:F6:66:10"; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "svc  battery1 (0x180f)"; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "char 2a19 (proxy right)"; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "poll  every 15s"; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "link  " + root.link; color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
            }
        ]
    }
}
