// 01 · Keycap Silhouette — two keycap trapezoids, battery = liquid fill level
// clipped to the keycap outline. Link glyph glows above the pair.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    function frac(p) { const n = parseFloat(p); return isNaN(n) ? 0 : n / 100; }

    Row {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10
        spacing: 40

        Repeater {
            model: [ { pct: root.lpct, tag: "L" }, { pct: root.rpct, tag: "R" } ]
            delegate: Canvas {
                width: 120; height: 150
                property real level: root.frac(modelData.pct)
                onLevelChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height;
                    // Keycap trapezoid path (narrower top, rounded corners).
                    ctx.beginPath();
                    ctx.moveTo(18, 14);
                    ctx.lineTo(w - 18, 14);
                    ctx.quadraticCurveTo(w - 4, 14, w - 4, 28);
                    ctx.lineTo(w - 16, h - 14);
                    ctx.quadraticCurveTo(w - 20, h - 4, w - 34, h - 4);
                    ctx.lineTo(34, h - 4);
                    ctx.quadraticCurveTo(20, h - 4, 16, h - 14);
                    ctx.lineTo(4, 28);
                    ctx.quadraticCurveTo(4, 14, 18, 14);
                    ctx.closePath();

                    ctx.save();
                    ctx.clip();
                    ctx.fillStyle = "#0a0f0c";
                    ctx.fillRect(0, 0, w, h);
                    const fillH = level * (h - 18);
                    const grad = ctx.createLinearGradient(0, h - fillH, 0, h);
                    grad.addColorStop(0, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85));
                    grad.addColorStop(1, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35));
                    ctx.fillStyle = grad;
                    ctx.fillRect(0, h - fillH, w, fillH);
                    ctx.restore();

                    ctx.lineWidth = 2;
                    ctx.strokeStyle = root.accent;
                    ctx.stroke();

                    ctx.fillStyle = "#e8fff2";
                    ctx.font = "bold 14px 'JetBrainsMono Nerd Font'";
                    ctx.textAlign = "center";
                    ctx.fillText(modelData.tag + " " + modelData.pct + (modelData.pct === "--" ? "" : "%"), w / 2, h / 2);
                }
            }
        }
    }

    Text {
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 14
        text: (root.link === "usb" ? "󰈷" : root.link === "ble" ? "󰂯" : "󰌐") + "  keeb link"
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
    }
}
