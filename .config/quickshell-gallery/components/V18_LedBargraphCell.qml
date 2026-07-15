// 18 · LED Bargraph — classic hardware VU ladder: a column of discrete LEDs
// per half, lit bottom-up green→amber→red like an old amp meter.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    function ledColor(i, total) {
        const frac = i / total;
        if (frac > 0.8) return "#ff4d4d";
        if (frac > 0.55) return "#ffb000";
        return "#5dff8a";
    }

    Row {
        anchors.centerIn: parent
        spacing: 50

        Repeater {
            model: [ { tag: "L", pct: root.lpct }, { tag: "R", pct: root.rpct } ]
            delegate: Column {
                spacing: 8
                Column {
                    id: ladder
                    spacing: 4
                    property int total: 12
                    property real pctVal: { const n = parseFloat(modelData.pct); return isNaN(n) ? 0 : n; }
                    Repeater {
                        model: ladder.total
                        delegate: Rectangle {
                            property int rIndex: ladder.total - 1 - index
                            width: 30; height: 8; radius: 2
                            color: (rIndex / ladder.total) * 100 < ladder.pctVal
                                   ? root.ledColor(rIndex, ladder.total)
                                   : Qt.rgba(1,1,1,0.06)
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.tag + " " + modelData.pct + (modelData.pct === "--" ? "" : "%")
                    color: "#cfcfcf"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
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
        font.pixelSize: 11
        font.letterSpacing: 2
    }
}
