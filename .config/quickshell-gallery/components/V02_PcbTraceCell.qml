// 02 · PCB Trace Map — L/R nodes joined by a copper trace; a signal pulse
// travels the curve on a loop, colored by link state.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    readonly property real p0x: width * 0.18
    readonly property real p0y: height * 0.5
    readonly property real p1x: width * 0.5
    readonly property real p1y: height * 0.18
    readonly property real p2x: width * 0.82
    readonly property real p2y: height * 0.5

    Canvas {
        id: board
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55);
            ctx.lineWidth = 3;
            ctx.beginPath();
            ctx.moveTo(root.p0x, root.p0y);
            ctx.quadraticCurveTo(root.p1x, root.p1y, root.p2x, root.p2y);
            ctx.stroke();

            for (const n of [[root.p0x, root.p0y, "L " + root.lpct], [root.p2x, root.p2y, "R " + root.rpct]]) {
                ctx.beginPath();
                ctx.arc(n[0], n[1], 16, 0, Math.PI * 2);
                ctx.fillStyle = "#0a0f0c";
                ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = root.accent;
                ctx.stroke();
                ctx.fillStyle = "#e8fff2";
                ctx.font = "11px 'JetBrainsMono Nerd Font'";
                ctx.textAlign = "center";
                ctx.fillText(n[2] + (n[2].endsWith("--") ? "" : "%"), n[0], n[1] + height * 0.22);
            }
        }
    }

    NumberAnimation on t { running: root.link !== "off"; loops: Animation.Infinite; from: 0; to: 1; duration: 1400 }
    property real t: 0

    Rectangle {
        visible: root.link !== "off"
        width: 8; height: 8; radius: 4
        color: "#ffffff"
        x: (1 - root.t) * (1 - root.t) * root.p0x + 2 * (1 - root.t) * root.t * root.p1x + root.t * root.t * root.p2x - 4
        y: (1 - root.t) * (1 - root.t) * root.p0y + 2 * (1 - root.t) * root.t * root.p1y + root.t * root.t * root.p2y - 4
        opacity: 0.9
    }

    Text {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 12
        text: root.link.toUpperCase()
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.letterSpacing: 2
    }
}
