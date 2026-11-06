// CPU + GPU temperature over time — two traces (CPU magenta, GPU amber, same
// colors the scope HUD uses for those subsystems) on a fixed °C axis, newest
// sample at the right edge, scrolling left across a window of 10m, 1h or 6h
// (picked on the back; the graph and the min/avg/max both follow it).
//
// Samples every 5s while the front's LIVE toggle is on. Off pauses sampling
// entirely (rather than dropping to a slow background poll like the other
// HUDs): the x-axis is real time, so a gap in the line honestly shows when
// nothing was recorded. The history lives in memory, but on start it is seeded
// from bin/thermal-log's on-disk samples (a row every 30s), so a reload doesn't
// empty the longer windows; the back says how much time the numbers cover.
// Pass `anchorBelow` to hang its top edge directly off another card's bottom
// (same convention as IssuesHud). Sits on the left edge, so it can stack under
// the issues cards. Drag to flip for min/avg/max over the window; CLEAR there
// restarts just those numbers, the graph keeps its history.
//
// Live data comes from scripts/temps.sh -> "epoch|cpuC|gpuC" ("--" = no sensor).

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
    // Selectable spans, in seconds. Samples are kept for the longest one so
    // widening the span shows what was already recorded.
    readonly property var spans: ({ "10m": 600, "1h": 3600, "6h": 21600 })
    readonly property int retainSec: 21600
    readonly property int windowSec: spans[spanPick.value] || 600
    // Longest sample spacing still drawn as one continuous line; anything
    // wider (LIVE was off, or a poll was missed) breaks the trace.
    readonly property int gapSec: 12
    // Rows seeded from thermal-log are 30s apart, so any pair touching one gets
    // a limit that tolerates a single missed row.
    readonly property int seedInterval: 30
    readonly property int seedGapSec: 75
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

    // [{ t: epochSec, cpu: °C, gpu: °C, seed?: true }], oldest first; NaN = no
    // reading. `seed` marks rows that came from thermal-log rather than the
    // live poll.
    property var samples: []

    function gapLimit(a, b) { return (a.seed || b.seed) ? hud.seedGapSec : hud.gapSec; }
    // How long a sample stands for when nothing follows it closely.
    function spacing(s) { return s.seed ? hud.seedInterval : hud.liveInterval / 1000; }

    // thermal-log columns: time pkg_C dimm_C fans gpu_pct gpu_W gpu_C load1 top3.
    // pkg_C is the same x86_pkg_temp zone this card reads, gpu_C the same
    // nvidia-smi figure; "-" (no reading) parses to NaN like "--" does live.
    function seed(text) {
        const rows = [];
        for (const line of (text || "").split("\n")) {
            if (!line || line[0] === "#") continue;
            const f = line.split("\t");
            const t = Math.floor(Date.parse(f[0]) / 1000);
            if (isNaN(t)) continue;
            rows.push({ t: t, cpu: parseFloat(f[1]), gpu: parseFloat(f[6]), seed: true });
        }
        // Live samples are newer and finer, so seed only what predates them.
        const firstLive = hud.samples.length > 0 ? hud.samples[0].t : Infinity;
        const cutoff = Math.floor(Date.now() / 1000) - hud.retainSec;
        hud.samples = rows.filter(s => s.t >= cutoff && s.t < firstLive).concat(hud.samples);
    }

    Process {
        id: seedRead
        command: ["sh", "-c", "tail -n " + (Math.ceil(hud.retainSec / hud.seedInterval) + 30)
                              + " ~/.local/state/thermal-log/samples.tsv 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: hud.seed(text) }
    }

    function record(line) {
        const p = (line || "").split("|");
        const t = parseInt(p[0]);
        if (isNaN(t)) return;
        const cutoff = t - hud.retainSec;
        hud.samples = hud.samples
            .concat([{ t: t, cpu: parseFloat(p[1]), gpu: parseFloat(p[2]) }])
            .filter(s => s.t >= cutoff);
    }

    // The samples inside the selected span, measured back from the newest.
    readonly property var windowed: {
        if (samples.length === 0) return [];
        const cutoff = samples[samples.length - 1].t - windowSec;
        return samples.filter(s => s.t >= cutoff);
    }

    // Min/avg/max only count samples from this epoch on; CLEAR moves it to now.
    property real statsSince: 0
    readonly property var statSamples: windowed.filter(s => s.t >= statsSince)
    readonly property int recordedSec:
        statSamples.length > 1 ? statSamples[statSamples.length - 1].t - statSamples[0].t : 0

    // The front's readout is the live reading: a seeded row is history, however
    // recent, so it never stands in for "now".
    readonly property var last:
        samples.length > 0 && !samples[samples.length - 1].seed ? samples[samples.length - 1] : null
    readonly property real cpuNow: last ? last.cpu : NaN
    readonly property real gpuNow: last ? last.gpu : NaN

    // Min/max are per reading. The average is weighted by how long each reading
    // stood (to the next sample, or its own spacing across a gap), so 30s seeded
    // rows and 5s live rows count by time rather than by how many there are.
    function stat(key) {
        const pts = hud.statSamples;
        let lo = Infinity, hi = -Infinity, sum = 0, wsum = 0;
        for (let i = 0; i < pts.length; i++) {
            const v = pts[i][key];
            if (isNaN(v)) continue;
            lo = Math.min(lo, v);
            hi = Math.max(hi, v);
            let w = hud.spacing(pts[i]);
            if (i + 1 < pts.length) {
                const dt = pts[i + 1].t - pts[i].t;
                if (dt <= hud.gapLimit(pts[i], pts[i + 1])) w = dt;
            }
            sum += v * w;
            wsum += w;
        }
        return wsum > 0 ? { min: lo, avg: sum / wsum, max: hi } : null;
    }
    readonly property var cpuStat: stat("cpu")
    readonly property var gpuStat: stat("gpu")

    function fmt(v) { return isNaN(v) ? "--" : Math.round(v) + "°C"; }
    function cell(st, k) { return st ? Math.round(st[k]) + "°C" : "--"; }
    // 45 -> "45s", 600 -> "10m", 5400 -> "1.5h".
    function spanText(sec) {
        return sec < 60   ? sec + "s"
             : sec < 3600 ? Math.round(sec / 60) + "m"
             :              Math.round(sec / 360) / 10 + "h";
    }

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
                text: hud.spanText(hud.windowSec) + " window"
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
                property var series: hud.windowed
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
                        let prev = null;
                        for (const s of pts) {
                            const v = s[key];
                            if (isNaN(v)) { prev = null; continue; }
                            const x = padL + w - ((now - s.t) / hud.windowSec) * w;
                            const y = yOf(v);
                            if (!prev || s.t - prev.t > hud.gapLimit(prev, s)) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                            prev = s;
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
                    visible: hud.windowed.length < 2
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

            OptionList {
                id: spanPick
                anchors { verticalCenter: backTitle.verticalCenter; right: parent.right; rightMargin: 14 }
                stateName: "temp-span"
                options: ["10m", "1h", "6h"]
                accent: hud.fg
            },

            IconButton {
                anchors { bottom: parent.bottom; right: parent.right; margins: 14 }
                icon: "󰆴"           // nf-md-delete
                label: "CLEAR"
                accent: hud.fg
                onClicked: hud.statsSince = Date.now() / 1000
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
                    text: "last " + hud.spanText(hud.windowSec) + " · "
                        + hud.spanText(hud.recordedSec) + " recorded · "
                        + hud.statSamples.length + " samples"
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
