// 03 · Radar Sweep — rotating gradient wedge around a center keyboard glyph;
// BLE sweeps continuously, USB holds a solid ring, off is static and dim.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Canvas {
        id: rings
        anchors.centerIn: parent
        width: Math.min(root.width, root.height) * 0.75
        height: width
        rotation: root.link === "ble" ? sweep.angle : 0

        RotationAnimation on rotation {
            id: sweep
            property real angle: 0
            running: root.link === "ble"
            loops: Animation.Infinite
            from: 0; to: 360
            duration: 2200
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height / 2, r = width / 2 - 6;
            for (const rr of [r, r * 0.66, r * 0.33]) {
                ctx.beginPath();
                ctx.arc(cx, cy, rr, 0, Math.PI * 2);
                ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35);
                ctx.lineWidth = 1;
                ctx.stroke();
            }
            if (root.link !== "off") {
                const grad = ctx.createConicalGradient ? null : null;
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(cx, cy);
                ctx.arc(cx, cy, r, -0.5, 0.5);
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4);
                ctx.fill();
                ctx.restore();
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.link === "usb" ? "󰈷" : root.link === "ble" ? "󰂯" : "󰌐"
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 30
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 14
        spacing: 24
        Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
        Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
    }
}
