// 13 · Battery Skeuomorph — literal AA-style cells with a striped charge
// fill and a nub, color shifting red/amber/green by level.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    function levelColor(p) {
        const n = parseFloat(p);
        if (isNaN(n)) return "#555555";
        if (n < 20) return "#ff4d4d";
        if (n < 50) return "#ffb000";
        return "#5dff8a";
    }

    Row {
        anchors.centerIn: parent
        spacing: 50

        Repeater {
            model: [ { tag: "L", pct: root.lpct }, { tag: "R", pct: root.rpct } ]
            delegate: Column {
                spacing: 8
                Item {
                    width: 70; height: 160
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        width: 26; height: 10
                        radius: 3
                        color: "#3a3a3a"
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width; height: parent.height - 10
                        radius: 8
                        color: "#1c1c1c"
                        border.color: "#4a4a4a"
                        border.width: 2
                        clip: true

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: { const n = parseFloat(modelData.pct); return isNaN(n) ? 0 : (n / 100) * parent.height; }
                            color: root.levelColor(modelData.pct)
                            Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

                            Repeater {
                                model: 8
                                delegate: Rectangle {
                                    y: index * 14 - 6
                                    rotation: 30
                                    width: 90; height: 4
                                    x: -20
                                    color: Qt.rgba(0,0,0,0.15)
                                }
                            }
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.tag + " " + modelData.pct + (modelData.pct === "--" ? "" : "%")
                    color: "#e8fff2"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }
            }
        }
    }

    Text {
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 14
        text: root.link.toUpperCase()
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.letterSpacing: 2
    }
}
