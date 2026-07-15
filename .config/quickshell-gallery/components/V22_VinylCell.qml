// 22 · Vinyl Record — a spinning record per half; the label's arc fills in
// as a progress ring reading the battery level, groove texture underneath.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Row {
        anchors.centerIn: parent
        spacing: 50

        Repeater {
            model: [ { tag: "L", pct: root.lpct }, { tag: "R", pct: root.rpct } ]
            delegate: Column {
                spacing: 8
                Item {
                    width: 130; height: 130
                    anchors.horizontalCenter: parent.horizontalCenter

                    Item {
                        id: disc
                        anchors.fill: parent
                        RotationAnimation on rotation {
                            running: root.link !== "off"
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 2800
                        }
                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                const cx = width/2, cy = height/2, r = width/2 - 2;
                                ctx.fillStyle = "#0d0d0d";
                                ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.fill();
                                ctx.strokeStyle = "#222";
                                for (let gr = r - 6; gr > r * 0.42; gr -= 5) {
                                    ctx.beginPath(); ctx.arc(cx, cy, gr, 0, Math.PI*2); ctx.stroke();
                                }
                                const pct = parseFloat(modelData.pct);
                                const frac = isNaN(pct) ? 0 : pct / 100;
                                ctx.strokeStyle = root.accent;
                                ctx.lineWidth = r * 0.4;
                                ctx.beginPath();
                                ctx.arc(cx, cy, r * 0.42, -Math.PI/2, -Math.PI/2 + frac * Math.PI * 2);
                                ctx.stroke();
                            }
                        }
                    }
                    Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "#e8e8e8" }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.tag + " " + modelData.pct + (modelData.pct === "--" ? "" : "%")
                    color: "#e8e8e8"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }
            }
        }
    }
}
