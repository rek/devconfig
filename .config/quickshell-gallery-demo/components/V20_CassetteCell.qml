// 20 · Cassette Tape — twin spinning reels, mixtape aesthetic; reels turn
// only while linked, one takes up "tape" as a proxy for charge used.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Rectangle {
        anchors.centerIn: parent
        width: root.width - 50; height: root.height - 70
        radius: 10
        color: "#2b2620"
        border.color: "#4a4238"
        border.width: 2

        Row {
            anchors.centerIn: parent
            spacing: 60

            Repeater {
                model: [ { tag: "L", pct: root.lpct }, { tag: "R", pct: root.rpct } ]
                delegate: Column {
                    spacing: 8
                    Item {
                        width: 90; height: 90
                        anchors.horizontalCenter: parent.horizontalCenter
                        Rectangle { anchors.fill: parent; radius: width/2; color: "#12100c"; border.color: "#5a5040"; border.width: 2 }
                        Rectangle {
                            anchors.centerIn: parent
                            width: { const n = parseFloat(modelData.pct); return isNaN(n) ? 40 : 24 + (n/100)*46; }
                            height: width; radius: width/2
                            color: "#3a352b"
                            border.color: "#8a7a5a"; border.width: 1
                            Behavior on width { NumberAnimation { duration: 500 } }

                            RotationAnimation on rotation {
                                running: root.link !== "off"
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 3000
                            }
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.9; height: 2
                                    color: "#12100c"
                                    rotation: index * 60
                                }
                            }
                        }
                        Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: "#12100c" }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.tag + " " + modelData.pct + (modelData.pct === "--" ? "" : "%")
                        color: "#e8dfc8"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                }
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 8
            text: "SIDE " + (root.link === "usb" ? "A · wired" : root.link === "ble" ? "B · wireless" : "— stopped")
            color: "#a89870"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }
}
