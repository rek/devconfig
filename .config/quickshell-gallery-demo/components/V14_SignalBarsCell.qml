// 14 · Signal Bars — cellular-style bars per half, tiered by battery level,
// with a soft pulsing glow while linked.
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    property real glowAmt: 0.2
    SequentialAnimation on glowAmt {
        running: root.link !== "off"
        loops: Animation.Infinite
        NumberAnimation { to: 0.6; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.2; duration: 900; easing.type: Easing.InOutSine }
    }

    Row {
        id: barsRow
        anchors.centerIn: parent
        spacing: 46

        Repeater {
            model: [ { tag: "L", pct: root.lpct }, { tag: "R", pct: root.rpct } ]
            delegate: Column {
                spacing: 10
                Row {
                    spacing: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            property real pctVal: { const n = parseFloat(modelData.pct); return isNaN(n) ? 0 : n; }
                            width: 14
                            height: 20 + index * 14
                            radius: 3
                            anchors.bottom: parent.bottom
                            color: pctVal >= (index + 1) * 25 ? root.accent : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.tag + " " + modelData.pct + (modelData.pct === "--" ? "" : "%")
                    color: root.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }
            }
        }
    }

    MultiEffect {
        source: barsRow
        anchors.fill: barsRow
        blurEnabled: true
        blur: 0.5
        brightness: root.glowAmt
        opacity: 0.5
    }
}
