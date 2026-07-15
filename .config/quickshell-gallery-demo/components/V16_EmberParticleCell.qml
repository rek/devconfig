// 16 · Ember Particles — small glowing sparks drift upward when charge is
// healthy; a sparse, ambient idle animation rather than a readout-first card.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    property real avg: { const l = parseFloat(root.lpct), r = parseFloat(root.rpct);
        const vals = [l, r].filter(v => !isNaN(v));
        return vals.length ? vals.reduce((a,b) => a+b, 0) / vals.length : 0; }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 16
        color: "#070707"
        radius: 8
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)
        border.width: 1
        clip: true

        Repeater {
            model: 14
            delegate: Rectangle {
                property real seed: index / 14
                width: 3 + (index % 3); height: width; radius: width / 2
                color: root.accent
                x: parent.width * seed
                y: parent.height
                opacity: 0

                SequentialAnimation on y {
                    running: root.avg > 15
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 220 }
                    NumberAnimation { to: -10; duration: 2600 + index * 80; easing.type: Easing.OutQuad }
                    PropertyAction { value: backdrop.height }
                }
                SequentialAnimation on opacity {
                    running: root.avg > 15
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 220 }
                    NumberAnimation { to: 0.9; duration: 300 }
                    PauseAnimation { duration: 1800 }
                    NumberAnimation { to: 0; duration: 500 }
                }
            }
        }
        Item { id: backdrop; anchors.fill: parent }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.link === "off" ? "resting" : "charged & drifting"
                color: Qt.rgba(1,1,1,0.5)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
            }
        }
    }
}
