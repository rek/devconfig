// 21 · Origami Fold — flat-shaded triangular facets suggest a folded paper
// plane; facet brightness reads as charge level, minimal palette.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Canvas {
        anchors.fill: parent
        anchors.margins: 16
        property real l: { const n = parseFloat(root.lpct); return isNaN(n) ? 0 : n / 100; }
        property real r: { const n = parseFloat(root.rpct); return isNaN(n) ? 0 : n / 100; }
        onLChanged: requestPaint()
        onRChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height, cx = w / 2, cy = h * 0.5;
            ctx.fillStyle = "#111318";
            ctx.fillRect(0, 0, w, h);

            function facet(pts, shade) {
                ctx.beginPath();
                ctx.moveTo(pts[0][0], pts[0][1]);
                for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
                ctx.closePath();
                const c = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25 + shade * 0.65);
                ctx.fillStyle = c;
                ctx.fill();
                ctx.strokeStyle = "#0a0b0e";
                ctx.lineWidth = 1.5;
                ctx.stroke();
            }

            facet([[cx, cy - h*0.32], [cx, cy + h*0.32], [w*0.12, cy + h*0.12]], l);
            facet([[cx, cy - h*0.32], [w*0.12, cy + h*0.12], [w*0.12, cy - h*0.08]], l * 0.7);
            facet([[cx, cy - h*0.32], [cx, cy + h*0.32], [w*0.88, cy + h*0.12]], r);
            facet([[cx, cy - h*0.32], [w*0.88, cy + h*0.12], [w*0.88, cy - h*0.08]], r * 0.7);
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 14
        spacing: 24
        Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: "#dfe6ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
        Text { text: root.link.toUpperCase(); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.letterSpacing: 2 }
        Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: "#dfe6ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
    }
}
