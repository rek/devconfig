// A single mixtape-style reel: spins while `spinning` is true, and its spool
// grows with `pct` (battery level). Recolored to the HUD's own accent instead
// of a literal tape-brown, so it reads as one family with the other green
// HUDs rather than an unrelated palette import.
//
//     CassetteReel { tag: "L"; pct: "84"; spinning: true; accent: "#00ff88" }

import QtQuick

Column {
    id: root
    property string tag: ""
    property string pct: "--"
    property bool spinning: false
    property color accent: "#00ff88"
    property real size: 74

    spacing: 6

    Item {
        width: root.size; height: root.size
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#050a06"
            border.color: Qt.darker(root.accent, 1.6)
            border.width: 2
        }

        Rectangle {
            id: spool
            anchors.centerIn: parent
            width: { const n = parseFloat(root.pct); return isNaN(n) ? root.size * 0.3 : root.size * (0.28 + (n / 100) * 0.5); }
            height: width
            radius: width / 2
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
            border.color: root.accent
            border.width: 1
            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

            RotationAnimation on rotation {
                running: root.spinning
                loops: Animation.Infinite
                from: 0; to: 360
                duration: 3000
            }
            Repeater {
                model: 3
                delegate: Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.88; height: 1.5
                    color: Qt.darker(root.accent, 1.3)
                    rotation: index * 60
                }
            }
        }
        Rectangle { anchors.centerIn: parent; width: 7; height: 7; radius: 3.5; color: root.accent }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.tag + " " + root.pct + (root.pct === "--" ? "" : "%")
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
    }
}
