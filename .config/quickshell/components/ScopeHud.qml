// Multi-channel oscilloscope — CPU/RAM/GPU as three overlaid phosphor traces
// on one CRT-style scope, replacing eww's old top-hud sparklines. Reclaims
// the freed-up top strip instead of stacking onto the already-tall top-right
// column. Always live (unlike TopCpu/TopMemHud) — a scrolling scope reading
// is expected motion, not the reorder-flicker that prompted those toggles.
//
// Colors match the original eww bar exactly: CPU magenta, RAM cyan, GPU
// amber — the synthwave Theme palette, not the green HUD family, since
// that's the language this data already spoke.
//
// Drag to flip for the git commit heatmap that used to share the eww window
// (scripts/git-heatmap.sh, 15 weeks × 7 days, cached 10min server-side).

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: hud

    readonly property color cpuColor: "#ff2bd6"
    readonly property color ramColor: "#00fff9"
    readonly property color gpuColor: "#ff9e00"
    readonly property int histLen: 45

    // Flush to the top (cardTopY always 0), exposed so the left (PrsHud/
    // IssuesHud) and right (DiskHud/statsCard/KeyboardHud/TopCpuHud) stacks
    // can both hang their top item directly off this card's bottom edge —
    // same anchorBelow/cardBottomY convention as IssuesHud.
    readonly property real cardTopY: 0
    readonly property real cardBottomY: cardTopY + card.cardHeight

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
    WlrLayershell.namespace: "qs-scope-hud"

    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

    // === Live metrics — same scripts the old eww top-hud used ===
    Poller {
        id: cpuPoll
        command: "~/.config/eww/scripts/cpu.sh"
        interval: 2000
        onValueChanged: hud.cpuHistory = hud.cpuHistory.concat([parseFloat(value) || 0]).slice(-hud.histLen)
    }
    Poller {
        id: ramPoll
        command: "free | awk '/Mem:/ {printf \"%.0f\", $3/$2 * 100}'"
        interval: 2000
        onValueChanged: hud.ramHistory = hud.ramHistory.concat([parseFloat(value) || 0]).slice(-hud.histLen)
    }
    Poller {
        id: gpuPoll
        command: "~/.config/eww/scripts/gpu.sh"
        interval: 3000
        onValueChanged: hud.gpuHistory = hud.gpuHistory.concat([parseFloat(value) || 0]).slice(-hud.histLen)
    }
    Poller {
        id: heatmapPoll
        command: "~/.config/eww/scripts/git-heatmap.sh"
        interval: 600000
    }
    readonly property var heatmapWeeks: {
        try { return JSON.parse(heatmapPoll.value || "[]"); } catch (e) { return []; }
    }
    property string hoverInfo: ""

    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []

    FlipCard {
        id: card
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 0
        cardWidth: hud.width
        cardHeight: 210
        cardRadius: 0
        borderWidth: 0
        background: "#28070b08"
        clickFrontToFlip: false
        dragToFlip: true

        // ============================================================
        // FRONT — the scope
        // ============================================================
        front: [
            Rectangle {
                id: scopeFrame
                anchors { top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom }
                anchors { topMargin: 0; leftMargin: 14; rightMargin: 14; bottomMargin: 14 }
                color: "#1c020503"
                radius: 0
                clip: true

                Canvas {
                    id: traceCanvas
                    anchors.fill: parent
                    property var cpuH: hud.cpuHistory
                    property var ramH: hud.ramHistory
                    property var gpuH: hud.gpuHistory
                    onCpuHChanged: requestPaint()
                    onRamHChanged: requestPaint()
                    onGpuHChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        // Graticule.
                        ctx.strokeStyle = "rgba(0, 255, 249, 0.08)";
                        ctx.lineWidth = 1;
                        for (let gy = 0; gy <= 4; gy++) {
                            const y = (height / 4) * gy;
                            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                        }
                        for (let gx = 0; gx <= 12; gx++) {
                            const x = (width / 12) * gx;
                            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
                        }

                        function trace(hist, color) {
                            if (hist.length < 2) return;
                            ctx.strokeStyle = color;
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            for (let i = 0; i < hist.length; i++) {
                                const x = (i / (hud.histLen - 1)) * width;
                                const y = height - (Math.max(0, Math.min(100, hist[i])) / 100) * height;
                                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                            // Glow pass — a wider, faint re-stroke of the same path.
                            ctx.save();
                            ctx.globalAlpha = 0.25;
                            ctx.lineWidth = 6;
                            ctx.stroke();
                            ctx.restore();
                        }

                        trace(cpuH, hud.cpuColor);
                        trace(ramH, hud.ramColor);
                        trace(gpuH, hud.gpuColor);
                    }
                }

                // CRT scanlines.
                Column {
                    anchors.fill: parent
                    spacing: 3
                    Repeater {
                        model: Math.max(0, Math.floor(scopeFrame.height / 4))
                        delegate: Rectangle { width: scopeFrame.width; height: 1; color: "#000000"; opacity: 0.18 }
                    }
                }
            }
        ]

        // ============================================================
        // BACK — git commit heatmap
        // ============================================================
        back: [
            Text {
                id: backTitle
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /git/commits.15w"
                color: "#00fff9"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
            },

            Text {
                anchors { top: parent.top; right: parent.right; margins: 14 }
                text: hud.hoverInfo || "hover a day for details"
                color: "#b58fcf"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            },

            Row {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: hud.heatmapWeeks
                    delegate: Column {
                        spacing: 3
                        Repeater {
                            model: modelData
                            delegate: Rectangle {
                                width: 16; height: 16; radius: 3
                                color: modelData.level === 0 ? "rgba(255,43,214,0.06)"
                                     : modelData.level === 1 ? "rgba(255,43,214,0.28)"
                                     : modelData.level === 2 ? "rgba(255,43,214,0.55)"
                                     : modelData.level === 3 ? "rgba(255,43,214,0.82)"
                                     :                          "#ff2bd6"
                                border.color: modelData.level === 4 ? "#ffb3ec" : "transparent"
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: hud.hoverInfo = modelData.date + "  ·  " + modelData.count + " commits"
                                    onExited: hud.hoverInfo = ""
                                }
                            }
                        }
                    }
                }
            }
        ]
    }
}
