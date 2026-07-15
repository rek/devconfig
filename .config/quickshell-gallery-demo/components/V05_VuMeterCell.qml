// 05 · VU Meter — twin analog gauges, brass-instrument styling, needle
// angle bound to battery percentage.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Row {
        anchors.centerIn: parent
        spacing: 30

        Repeater {
            model: [ root.lpct, root.rpct ]
            delegate: Item {
                width: 160; height: 160
                property real pct: { const n = parseFloat(modelData); return isNaN(n) ? 0 : n; }
                property real angle: -110 + (pct / 100) * 220

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const cx = width / 2, cy = height / 2, r = width / 2 - 14;
                        ctx.lineWidth = 8;
                        ctx.strokeStyle = "#2a2118";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, Math.PI * 0.72, Math.PI * 2.28);
                        ctx.stroke();
                        ctx.strokeStyle = root.accent;
                        ctx.lineWidth = 3;
                        for (let i = 0; i <= 10; i++) {
                            const a = Math.PI * 0.72 + (i / 10) * Math.PI * 1.56;
                            ctx.beginPath();
                            ctx.moveTo(cx + Math.cos(a) * (r - 10), cy + Math.sin(a) * (r - 10));
                            ctx.lineTo(cx + Math.cos(a) * (r + 2), cy + Math.sin(a) * (r + 2));
                            ctx.stroke();
                        }
                    }
                }

                Rectangle {
                    id: needle
                    width: 3; height: parent.height / 2 - 20
                    color: "#ffcf6b"
                    anchors.bottom: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    transformOrigin: Item.Bottom
                    rotation: parent.angle
                    Behavior on rotation { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 14; height: 14; radius: 7
                    color: "#ffcf6b"
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (index === 0 ? "L " : "R ") + modelData + (modelData === "--" ? "" : "%")
                    color: root.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }
            }
        }
    }
}
