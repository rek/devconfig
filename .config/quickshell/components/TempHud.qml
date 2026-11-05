// CPU + GPU temperature over time — two traces (CPU magenta, GPU amber, same
// colors the scope HUD uses for those subsystems) on a fixed °C axis, newest
// sample at the right edge, scrolling left across a 10-minute window.
//
// Samples every 5s while the front's LIVE toggle is on. Off pauses sampling
// entirely (rather than dropping to a slow background poll like the other
// HUDs): the x-axis is real time, so a gap in the line honestly shows when
// nothing was recorded. The history lives in memory only — it restarts empty
// when quickshell reloads.
// Pass `anchorBelow` to hang its top edge directly off another card's bottom
// (same convention as IssuesHud). Sits on the left edge, so it can stack under
// the issues cards. Drag to flip for min/avg/max over the window.
//
// Data comes from scripts/temps.sh -> "epoch|cpuC|gpuC" ("--" = no sensor).

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: hud

    property var anchorBelow: null
    property int anchorGap: 20
    property int leftMargin: 24

    readonly property color cpuColor: Theme.magenta
    readonly property color gpuColor: "#ff9e00"

    readonly property int liveInterval: 5000
    readonly property int windowSec: 600
    // Longest sample spacing still drawn as one continuous line; anything
    // wider (LIVE was off, or a poll was missed) breaks the trace.
    readonly property int gapSec: 12
    // Fixed °C axis so a trace's height means the same thing at a glance.
    readonly property real yMin: 30
    readonly property real yMax: 110

    screen: {
        for (let s of Quickshell.screens) {
            if (s.name === "eDP-2") return s;
        }
        return Quickshell.screens[0];
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-temp-hud"

    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

    Poller {
        id: tempPoll
        command: "~/.config/quickshell/scripts/temps.sh"
        interval: hud.liveInterval
        running: live.value
        onValueChanged: hud.record(value)
    }

    // [{ t: epochSec, cpu: °C, gpu: °C }], oldest first; NaN = no reading.
    property var samples: []

    function record(line) {
        const p = (line || "").split("|");
        const t = parseInt(p[0]);
        if (isNaN(t)) return;
        const cutoff = t - hud.windowSec;
        hud.samples = hud.samples
            .concat([{ t: t, cpu: parseFloat(p[1]), gpu: parseFloat(p[2]) }])
            .filter(s => s.t >= cutoff);
    }

    readonly property var last: samples.length > 0 ? samples[samples.length - 1] : null
    readonly property real cpuNow: last ? last.cpu : NaN
    readonly property real gpuNow: last ? last.gpu : NaN

    function stat(key) {
        let lo = Infinity, hi = -Infinity, sum = 0, n = 0;
        for (const s of hud.samples) {
            const v = s[key];
            if (isNaN(v)) continue;
            lo = Math.min(lo, v);
            hi = Math.max(hi, v);
            sum += v;
            n++;
        }
        return n > 0 ? { min: lo, avg: sum / n, max: hi } : null;
    }
    readonly property var cpuStat: stat("cpu")
    readonly property var gpuStat: stat("gpu")

    function fmt(v) { return isNaN(v) ? "--" : Math.round(v) + "°C"; }
    function cell(st, k) { return st ? Math.round(st[k]) + "°C" : "--"; }

    // Heat colour: green < 60, yellow < 75, orange < 90, red above — same
    // ramp as the stats card's TMP row.
    function heat(t) {
        return isNaN(t) ? "#446655"
             : t < 60 ? "#7fffaf"
             : t < 75 ? "#ffe14d"
             : t < 90 ? "#ff9a2e"
             :          "#ff3b3b";
    }

    readonly property color fg: live.value ? "#00ff88" : "#446655"

    readonly property real cardTopY:
        hud.anchorBelow ? (hud.anchorBelow.cardBottomY + hud.anchorGap)
                        : (hud.height * 0.35 + 143 + 220 + 20)
    readonly property real cardBottomY: cardTopY + card.cardHeight

    FlipCard {
        id: card
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: hud.leftMargin
        anchors.topMargin: hud.cardTopY
        cardWidth: 380
        cardHeight: 212
        borderColor: hud.fg
        background: "#b8070b08"
        clickFrontToFlip: false
        dragToFlip: true

        // ============================================================
        // FRONT — live readout + temperature graph
        // ============================================================
        front: [
            Text {
                id: title
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /sys/thermal.temps"
                color: hud.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            },

            ToggleButton {
                id: live
                anchors { top: parent.top; right: parent.right; margins: 14 }
                stateName: "temp-live"
                initial: "on"
                label: "LIVE"
                iconOn:  ""
                iconOff: ""
                accent: hud.fg
            },

            Rectangle {
                id: divider
                anchors {
                    top: title.bottom; left: parent.left; right: parent.right
                    topMargin: 10; leftMargin: 14; rightMargin: 14
                }
                height: 1
                color: "#1a3322"
            },

            Row {
                id: readout
                anchors { top: divider.bottom; left: parent.left; topMargin: 10; leftMargin: 14 }
                spacing: 26

                Row {
                    spacing: 8
                    Rectangle { width: 14; height: 3; color: hud.cpuColor; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "CPU"; color: hud.cpuColor; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: hud.fmt(hud.cpuNow); color: hud.heat(hud.cpuNow); font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    spacing: 8
                    Rectangle { width: 14; height: 3; color: hud.gpuColor; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "GPU"; color: hud.gpuColor; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: hud.fmt(hud.gpuNow); color: hud.heat(hud.gpuNow); font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
            },

            Text {
                anchors { right: parent.right; rightMargin: 14; verticalCenter: readout.verticalCenter }
                text: (hud.windowSec / 60) + "m window"
                color: "#446655"
                font.family: Theme.fontFamily
                font.pixelSize: 10
            },

            Canvas {
                id: graph
                anchors {
                    top: readout.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                    topMargin: 8; leftMargin: 14; rightMargin: 14; bottomMargin: 14
                }
                property var series: hud.samples
                onSeriesChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const padL = 26;                   // room for the °C labels
                    const w = width - padL;
                    const h = height;
                    function yOf(v) {
                        const c = Math.max(hud.yMin, Math.min(hud.yMax, v));
                        return h - ((c - hud.yMin) / (hud.yMax - hud.yMin)) * h;
                    }

                    // Gridlines + axis labels; 100° (throttle territory) in red.
                    ctx.font = "9px 'JetBrainsMono Nerd Font'";
                    ctx.textBaseline = "middle";
                    ctx.lineWidth = 1;
                    for (const g of [40, 60, 80, 100]) {
                        const y = Math.round(yOf(g)) + 0.5;
                        ctx.strokeStyle = g === 100 ? "rgba(255, 59, 59, 0.28)" : "rgba(0, 255, 136, 0.10)";
                        ctx.beginPath(); ctx.moveTo(padL, y); ctx.lineTo(width, y); ctx.stroke();
                        ctx.fillStyle = g === 100 ? "#a33" : "#446655";
                        ctx.fillText(String(g), 0, y);
                    }

                    const pts = series;
                    if (pts.length < 2) return;
                    const now = pts[pts.length - 1].t;

                    function trace(key, color) {
                        ctx.strokeStyle = color;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        let prevT = -1;
                        for (const s of pts) {
                            const v = s[key];
                            if (isNaN(v)) { prevT = -1; continue; }
                            const x = padL + w - ((now - s.t) / hud.windowSec) * w;
                            const y = yOf(v);
                            if (prevT < 0 || s.t - prevT > hud.gapSec) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                            prevT = s.t;
                        }
                        ctx.lineWidth = 2;
                        ctx.stroke();
                        // Glow pass — a wider, faint re-stroke of the same path.
                        ctx.save();
                        ctx.globalAlpha = 0.25;
                        ctx.lineWidth = 6;
                        ctx.stroke();
                        ctx.restore();
                    }

                    trace("cpu", hud.cpuColor);
                    trace("gpu", hud.gpuColor);
                }

                Text {
                    anchors.centerIn: parent
                    visible: hud.samples.length < 2
                    text: live.value ? "sampling…" : "paused — toggle LIVE to record"
                    color: "#446655"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        ]

        // ============================================================
        // BACK — min / avg / max over the window
        // ============================================================
        back: [
            Text {
                id: backTitle
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /sys/thermal.stats"
                color: hud.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            },

            Rectangle {
                id: backDivider
                anchors {
                    top: backTitle.bottom; left: parent.left; right: parent.right
                    topMargin: 10; leftMargin: 14; rightMargin: 14
                }
                height: 1
                color: "#1a3322"
            },

            Column {
                anchors {
                    top: backDivider.bottom; left: parent.left
                    topMargin: 14; leftMargin: 14
                }
                spacing: 10

                Row {
                    Text { width: 70; text: ""; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { width: 80; text: "MIN"; color: "#446655"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                    Text { width: 80; text: "AVG"; color: "#446655"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                    Text { width: 80; text: "MAX"; color: "#446655"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                }
                Row {
                    Text { width: 70; text: "CPU"; color: hud.cpuColor; font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true }
                    Text { width: 80; text: hud.cell(hud.cpuStat, "min"); color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.fontFamily; font.pixelSize: 13 }
                    Text { width: 80; text: hud.cell(hud.cpuStat, "avg"); color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.fontFamily; font.pixelSize: 13 }
                    Text { width: 80; text: hud.cell(hud.cpuStat, "max"); color: hud.heat(hud.cpuStat ? hud.cpuStat.max : NaN); font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true }
                }
                Row {
                    Text { width: 70; text: "GPU"; color: hud.gpuColor; font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true }
                    Text { width: 80; text: hud.cell(hud.gpuStat, "min"); color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.fontFamily; font.pixelSize: 13 }
                    Text { width: 80; text: hud.cell(hud.gpuStat, "avg"); color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.fontFamily; font.pixelSize: 13 }
                    Text { width: 80; text: hud.cell(hud.gpuStat, "max"); color: hud.heat(hud.gpuStat ? hud.gpuStat.max : NaN); font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true }
                }

                Item { width: 1; height: 4 }

                Text {
                    text: "last " + (hud.windowSec / 60) + " min · " + hud.samples.length + " samples"
                    color: "#446655"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                Text {
                    text: "LIVE on = sample every " + (hud.liveInterval / 1000) + "s"
                    color: "#446655"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                Text {
                    text: "LIVE off = sampling paused, history kept"
                    color: "#446655"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        ]
    }
}
