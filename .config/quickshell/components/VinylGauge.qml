// A single spinning "disk" gauge: a record with a progress-ring label
// standing in for the label area, filled clockwise to `pct`. Whether it
// spins is entirely up to the caller via `spinning` (e.g. bind it to a
// shared hover state to spin a whole cluster of gauges together).
//
//     VinylGauge { tag: "ROOT"; pct: 99; accent: "#ff4d4d"; spinning: cardHovered }

import QtQuick

Column {
    id: root
    property string tag: ""
    property real pct: 0
    property color accent: "#00ff88"
    property real size: 92
    property bool spinning: true

    spacing: 6

    Item {
        width: root.size; height: root.size
        anchors.horizontalCenter: parent.horizontalCenter

        Item {
            id: disc
            anchors.fill: parent
            RotationAnimation on rotation {
                running: true
                paused: !root.spinning
                loops: Animation.Infinite
                from: 0; to: 360
                duration: 6000
            }
            Canvas {
                anchors.fill: parent
                property real p: root.pct
                property color c: root.accent
                onPChanged: requestPaint()
                onCChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const cx = width / 2, cy = height / 2, r = width / 2 - 2;
                    ctx.fillStyle = "#050805";
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill();
                    ctx.strokeStyle = "#1c1c1c";
                    for (let gr = r - 6; gr > r * 0.44; gr -= 5) {
                        ctx.beginPath(); ctx.arc(cx, cy, gr, 0, Math.PI * 2); ctx.stroke();
                    }
                    const frac = Math.max(0, Math.min(1, p / 100));
                    ctx.strokeStyle = c;
                    ctx.lineWidth = r * 0.38;
                    ctx.beginPath();
                    ctx.arc(cx, cy, r * 0.44, -Math.PI / 2, -Math.PI / 2 + frac * Math.PI * 2);
                    ctx.stroke();
                }
            }
        }
        Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "#e8e8e8" }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.tag + " " + Math.round(root.pct) + "%"
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
    }
}
