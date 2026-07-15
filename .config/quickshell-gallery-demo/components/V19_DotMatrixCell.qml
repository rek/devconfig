// 19 · Dot Matrix — percentages rendered as a coarse LED dot-matrix
// numeral field (5x7 glyphs), airport-departure-board flavored.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    // 5x7 bitmap font, digits 0-9, '-', '%', space, and the uppercase
    // letters needed for LINK/AVG rows (L R B U S E O F A V G N K I).
    readonly property var glyphs: ({
        "0": [0x1E,0x11,0x13,0x15,0x19,0x11,0x1E], "1": [0x04,0x0C,0x04,0x04,0x04,0x04,0x0E],
        "2": [0x1E,0x01,0x01,0x1E,0x10,0x10,0x1F], "3": [0x1E,0x01,0x01,0x0E,0x01,0x01,0x1E],
        "4": [0x02,0x06,0x0A,0x12,0x1F,0x02,0x02], "5": [0x1F,0x10,0x1E,0x01,0x01,0x11,0x0E],
        "6": [0x0E,0x10,0x10,0x1E,0x11,0x11,0x0E], "7": [0x1F,0x01,0x02,0x04,0x08,0x08,0x08],
        "8": [0x0E,0x11,0x11,0x0E,0x11,0x11,0x0E], "9": [0x0E,0x11,0x11,0x0F,0x01,0x01,0x0E],
        "-": [0,0,0,0x1F,0,0,0], "%": [0x19,0x19,0x02,0x04,0x08,0x13,0x13],
        " ": [0,0,0,0,0,0,0],
        "A": [0x0E,0x11,0x11,0x1F,0x11,0x11,0x11], "B": [0x1E,0x11,0x11,0x1E,0x11,0x11,0x1E],
        "E": [0x1F,0x10,0x10,0x1E,0x10,0x10,0x1F], "F": [0x1F,0x10,0x10,0x1E,0x10,0x10,0x10],
        "G": [0x0E,0x11,0x10,0x17,0x11,0x11,0x0E], "I": [0x0E,0x04,0x04,0x04,0x04,0x04,0x0E],
        "K": [0x11,0x12,0x14,0x18,0x14,0x12,0x11], "L": [0x10,0x10,0x10,0x10,0x10,0x10,0x1F],
        "N": [0x11,0x19,0x15,0x13,0x11,0x11,0x11], "O": [0x0E,0x11,0x11,0x11,0x11,0x11,0x0E],
        "R": [0x1E,0x11,0x11,0x1E,0x14,0x12,0x11], "S": [0x1E,0x10,0x10,0x0E,0x01,0x01,0x1E],
        "U": [0x11,0x11,0x11,0x11,0x11,0x11,0x0E], "V": [0x11,0x11,0x11,0x11,0x11,0x0A,0x04],
    })

    function drawText(ctx, text, ox, oy, dot, gap, color) {
        let cx = ox;
        for (const ch of text.split("")) {
            const bits = root.glyphs[ch];
            if (bits) {
                for (let row = 0; row < 7; row++) {
                    for (let col = 0; col < 5; col++) {
                        if (bits[row] & (1 << (4 - col))) {
                            ctx.fillStyle = color;
                            ctx.fillRect(cx + col * dot, oy + row * dot, dot - 1, dot - 1);
                        }
                    }
                }
            }
            cx += (5 * dot) + gap;
        }
        return cx;
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 16
        color: "#0c0c0c"
        radius: 6

        Canvas {
            anchors.fill: parent
            property string l: root.lpct
            property string r: root.rpct
            property string lk: root.link
            onLChanged: requestPaint()
            onRChanged: requestPaint()
            onLkChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const dot = 4, gap = 3;
                const ln = parseFloat(root.l), rn = parseFloat(root.r);
                const avg = (isNaN(ln) || isNaN(rn)) ? "--" : Math.round((ln + rn) / 2).toString();
                const lt = "L " + (root.l === "--" ? "--" : root.l + "%");
                const rt = "R " + (root.r === "--" ? "--" : root.r + "%");
                const kt = "LINK " + lk.toUpperCase();
                const at = "AVG " + (avg === "--" ? "--" : avg + "%");
                drawText(ctx, lt, 24, 14, dot, gap, "#ff8a00");
                drawText(ctx, rt, 24, 52, dot, gap, "#ff8a00");
                drawText(ctx, kt, 24, 90, dot, gap, "#ff8a00");
                drawText(ctx, at, 24, 128, dot, gap, "#ff8a00");
            }
        }
    }
}
