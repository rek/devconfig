// 12 · Blueprint — schematic dot-matrix outline of the Lily58 split halves
// on graph paper, with a connection line pulsing between them.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 14
        color: "#0a1a3a"
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
        border.width: 1

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                for (let gx = 0; gx < width; gx += 16) { ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke(); }
                for (let gy = 0; gy < height; gy += 16) { ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke(); }

                function half(ox, cols) {
                    ctx.fillStyle = "#bcd4ff";
                    for (let r = 0; r < 4; r++) {
                        for (let c = 0; c < cols; c++) {
                            const stagger = (c % 2 === 0) ? 0 : 6;
                            ctx.beginPath();
                            ctx.arc(ox + c * 18, height * 0.28 + stagger + r * 18, 3, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }
                }
                half(width * 0.1, 5);
                half(width * 0.56, 5);

                ctx.strokeStyle = root.accent;
                ctx.lineWidth = 1.5;
                ctx.setLineDash([4, 4]);
                ctx.beginPath();
                ctx.moveTo(width * 0.1 + 4 * 18, height * 0.28 + 1.5 * 18);
                ctx.lineTo(width * 0.56, height * 0.28 + 1.5 * 18);
                ctx.stroke();
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 10
            spacing: 24
            Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: "#bcd4ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
            Text { text: root.link.toUpperCase(); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.letterSpacing: 2 }
            Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: "#bcd4ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
        }
    }
}
