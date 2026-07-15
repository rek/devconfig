// 07 · Holographic Hex — hexagonal card with a soft cyan/magenta glow bloom
// (MultiEffect), for a glassy sci-fi HUD feel.
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    Canvas {
        id: hex
        anchors.centerIn: parent
        width: Math.min(root.width, root.height) * 0.85
        height: width * 0.86
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height / 2, r = width / 2 - 4;
            ctx.beginPath();
            for (let i = 0; i < 6; i++) {
                const a = Math.PI / 3 * i - Math.PI / 2;
                const px = cx + r * Math.cos(a), py = cy + r * Math.sin(a);
                if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
            }
            ctx.closePath();
            const grad = ctx.createLinearGradient(0, 0, width, height);
            grad.addColorStop(0, "#ff2bd680");
            grad.addColorStop(1, "#00fff980");
            ctx.fillStyle = "#0a0614";
            ctx.fill();
            ctx.lineWidth = 3;
            ctx.strokeStyle = grad;
            ctx.stroke();
        }
    }

    MultiEffect {
        source: hex
        anchors.fill: hex
        blurEnabled: true
        blur: 0.4
        brightness: 0.15
        saturation: 0.3
        opacity: 0.7
    }

    Column {
        anchors.centerIn: parent
        spacing: 4
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.link === "usb" ? "USB LINK" : root.link === "ble" ? "BLE LINK" : "NO LINK"
            color: "#f6e9ff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.letterSpacing: 3
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: "#00fff9"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; font.bold: true }
            Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: "#ff2bd6"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; font.bold: true }
        }
    }
}
