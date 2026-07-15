// 10 · Outrun Horizon — magenta/cyan sunset grid, a rising "sun" arc whose
// fill height reads as average battery charge.
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
        radius: 8
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a0b2e" }
            GradientStop { position: 1.0; color: "#3a0f3f" }
        }

        Canvas {
            anchors.fill: parent
            property real level: root.avg
            onLevelChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2, cy = height * 0.62, r = width * 0.28;
                ctx.save();
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.clip();
                const grad = ctx.createLinearGradient(0, 0, 0, height);
                grad.addColorStop(0, "#ff2bd6");
                grad.addColorStop(1, "#00fff9");
                ctx.fillStyle = grad;
                const fillY = cy + r - (level / 100) * (r * 2);
                ctx.fillRect(0, fillY, width, height);
                ctx.restore();
                ctx.lineWidth = 2;
                ctx.strokeStyle = "#ffe6fb";
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.stroke();

                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.5);
                for (let i = 0; i < 6; i++) {
                    const gy = cy + r + i * 8 + i * i * 1.5;
                    if (gy > height) break;
                    ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke();
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 10
            spacing: 20
            Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: "#ffe6fb"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: "#ffe6fb"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
        }
    }
}
