// 11 · Sonar Ping — concentric rings expand outward on a loop when linked,
// like a sonar blip. Off state shows a single dim static ring.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Item {
        anchors.centerIn: parent
        width: 1; height: 1

        Repeater {
            model: 3
            delegate: Rectangle {
                anchors.centerIn: parent
                radius: width / 2
                color: "transparent"
                border.color: root.accent
                border.width: 2
                width: 20; height: 20
                opacity: 0

                SequentialAnimation on width {
                    running: root.link !== "off"
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 500 }
                    NumberAnimation { from: 20; to: 260; duration: 1500; easing.type: Easing.OutCubic }
                    PropertyAction { value: 20 }
                    PauseAnimation { duration: (2 - index) * 500 }
                }
                SequentialAnimation on height {
                    running: root.link !== "off"
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 500 }
                    NumberAnimation { from: 20; to: 260; duration: 1500; easing.type: Easing.OutCubic }
                    PropertyAction { value: 20 }
                    PauseAnimation { duration: (2 - index) * 500 }
                }
                SequentialAnimation on opacity {
                    running: root.link !== "off"
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 500 }
                    NumberAnimation { from: 0.9; to: 0; duration: 1500 }
                    PauseAnimation { duration: (2 - index) * 500 }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.link === "usb" ? "󰈷" : root.link === "ble" ? "󰂯" : "󰌐"
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 26
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        spacing: 20
        Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
        Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
    }
}
