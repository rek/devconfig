// 06 · Oscilloscope — a phosphor-green trace whose shape encodes link state:
// square wave for USB (clean signal), sine for BLE (radio), flatline for off.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    property real phase: 0
    NumberAnimation on phase {
        running: root.link !== "off"
        loops: Animation.Infinite
        from: 0; to: Math.PI * 2
        duration: 1800
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 16
        color: "#05100a"
        border.color: root.accent
        border.width: 2
        radius: 4

        Canvas {
            id: scope
            anchors.fill: parent
            anchors.margins: 10
            property real ph: root.phase
            onPhChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15);
                for (let gy = 0; gy < height; gy += 20) { ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke(); }
                for (let gx = 0; gx < width; gx += 20) { ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke(); }

                ctx.strokeStyle = root.accent;
                ctx.lineWidth = 2;
                ctx.beginPath();
                const mid = height / 2;
                for (let x = 0; x <= width; x += 2) {
                    let y = mid;
                    if (root.link === "ble") {
                        y = mid + Math.sin(x * 0.06 + ph) * height * 0.28;
                    } else if (root.link === "usb") {
                        y = mid + (Math.floor((x * 0.1 + ph * 4) % 20 < 10) ? -1 : 1) * height * 0.28;
                    }
                    if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                }
                ctx.stroke();
            }
        }
    }

    Row {
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 4
        spacing: 24
        Text { text: "L " + root.lpct + (root.lpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
        Text { text: "R " + root.rpct + (root.rpct === "--" ? "" : "%"); color: root.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
    }
}
