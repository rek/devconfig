// 24 · Aurora Wave — flowing layered gradient waves, calm and ambient; the
// numerals sit softly on top rather than being the focal point.
import QtQuick

Item {
    id: root
    property string link: "off"
    property string lpct: "--"
    property string rpct: "--"
    property color accent: "#446655"

    property real t: 0
    NumberAnimation on t {
        running: true
        loops: Animation.Infinite
        from: 0; to: Math.PI * 2
        duration: 6000
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 16
        radius: 10
        color: "#040a12"
        clip: true

        Canvas {
            anchors.fill: parent
            property real ph: root.t
            onPhChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const colors = ["rgba(0,255,249,0.16)", "rgba(255,43,214,0.16)", "rgba(93,255,138,0.16)"];
                for (let layer = 0; layer < 3; layer++) {
                    ctx.beginPath();
                    ctx.moveTo(0, height);
                    for (let x = 0; x <= width; x += 8) {
                        const y = height * 0.55
                                 + Math.sin(x * 0.02 + ph + layer * 2) * 22
                                 + layer * 14;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(width, height);
                    ctx.closePath();
                    ctx.fillStyle = colors[layer];
                    ctx.fill();
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 26
                Text { text: root.lpct + (root.lpct === "--" ? "" : "%"); color: "#eafffb"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 30; font.weight: Font.Light }
                Text { text: root.rpct + (root.rpct === "--" ? "" : "%"); color: "#eafffb"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 30; font.weight: Font.Light }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.link === "off" ? "quiet" : root.link
                color: Qt.rgba(1,1,1,0.5)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
    }
}
