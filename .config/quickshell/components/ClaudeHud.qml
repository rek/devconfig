// Claude Code usage — session (5h) and weekly (7d) rate-limit meters, sourced
// straight from Omarchy's own official usage collector (omarchy-agent-usage-claude,
// the same command behind the "Agents" bar plugin's panel) rather than a hand-
// rolled transcript parse. That tool hits Anthropic's authoritative OAuth usage
// endpoint and caches aggressively, so polling it here is cheap.
//
// Replaces the old eww claude-hud (bottom-right) — that spot's since been
// claimed by the ddterm/steam/orca/blender launcher row, so this extends the
// second inner right column (TopCpuHud/TopMemHud) downward instead, the same
// column freed up when the eww widget was removed for being buried in the bar.
// Pass `anchorBelow` (same convention as IssuesHud) to hang under a sibling.
//
// Cyan-primary, the Theme singleton's synthwave accent — same distinguishing
// choice the old eww claude-hud made against the green sys-stat HUDs. Drag to
// flip for today's token breakdown by model.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: hud

    property var anchorBelow: null
    property int anchorGap: 20
    property int rightMargin: 24

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
    WlrLayershell.namespace: "qs-claude-hud"

    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

    // The official collector caches its own network probe and transcript
    // scan internally (a cold run is a ~4s scan, a warm one ~60ms), so a 60s
    // poll here stays glanceable without re-triggering that work every time.
    Poller {
        id: usagePoll
        command: "omarchy-agent-usage-claude"
        interval: 60000
    }

    readonly property var usage: {
        try { return JSON.parse(usagePoll.value || "{}"); } catch (e) { return {}; }
    }
    readonly property var limits: usage.limits || []
    function findLimit(substr) {
        for (const l of limits) {
            if (String(l.label || "").indexOf(substr) !== -1) return l;
        }
        return null;
    }
    readonly property var sessionLimit: hud.findLimit("Session")
    readonly property var weeklyLimit: hud.findLimit("Weekly (7-day)")
    readonly property real sessionPct: sessionLimit ? (sessionLimit.percent * 100) : 0
    readonly property real weeklyPct: weeklyLimit ? (weeklyLimit.percent * 100) : 0
    readonly property bool ready: usage.ready === true && limits.length > 0

    readonly property var modelRows: {
        const obj = usage.todayTokensByModel || {};
        const rows = Object.keys(obj).map(k => ({ name: k, tokens: Number(obj[k]) || 0 }));
        rows.sort((a, b) => b.tokens - a.tokens);
        return rows;
    }

    function fmtTokens(n) {
        n = Number(n) || 0;
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M";
        if (n >= 1000) return (n / 1000).toFixed(1) + "K";
        return String(Math.round(n));
    }

    function fmtRemaining(iso) {
        if (!iso) return "--";
        const target = new Date(iso);
        if (isNaN(target.getTime())) return "--";
        let secs = Math.max(0, Math.floor((target.getTime() - Date.now()) / 1000));
        if (secs === 0) return "0m";
        const d = Math.floor(secs / 86400); secs %= 86400;
        const h = Math.floor(secs / 3600); secs %= 3600;
        const m = Math.floor(secs / 60);
        if (d) return d + "d " + h + "h";
        if (h) return h + "h " + (m < 10 ? "0" + m : m) + "m";
        return m + "m";
    }

    // Green under 70%, amber under 90%, red beyond — same severity read the
    // other HUDs use, but on the cyan accent family.
    readonly property color fg: "#00fff9"
    function severity(pct) {
        if (pct >= 90) return "#ff4d4d";
        if (pct >= 70) return "#ffb000";
        return hud.fg;
    }

    readonly property real cardTopY:
        hud.anchorBelow ? (hud.anchorBelow.cardBottomY + hud.anchorGap)
                        : (hud.height * 0.35 + 143 + 220 + 20)
    readonly property real cardBottomY: cardTopY + card.cardHeight

    FlipCard {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: hud.rightMargin
        anchors.topMargin: hud.cardTopY
        cardWidth: 380
        cardHeight: 224
        borderColor: hud.severity(Math.max(hud.sessionPct, hud.weeklyPct))
        background: "#b8070b08"
        clickFrontToFlip: false
        dragToFlip: true

        // ============================================================
        // FRONT — session + weekly rate-limit meters
        // ============================================================
        front: [
            Text {
                id: title
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /ai/claude.usage"
                color: hud.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            },

            Text {
                anchors { top: parent.top; right: parent.right; margins: 14 }
                text: hud.usage.tierLabel ? String(hud.usage.tierLabel).toUpperCase() : "--"
                color: Theme.magenta
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
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

            Column {
                anchors {
                    top: divider.bottom; left: parent.left; right: parent.right
                    bottom: parent.bottom
                    topMargin: 10; leftMargin: 14; rightMargin: 14; bottomMargin: 14
                }
                spacing: 8
                visible: hud.ready

                StatRow {
                    label: "SESSION"; suffix: "%"
                    accent: hud.severity(hud.sessionPct)
                    valueColor: hud.severity(hud.sessionPct)
                    value: hud.sessionPct.toFixed(0)
                    showBar: true; pct: hud.sessionPct
                }
                Text {
                    text: hud.sessionLimit ? ("resets in " + hud.fmtRemaining(hud.sessionLimit.resetsAt)) : "--"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                StatRow {
                    label: "WEEKLY"; suffix: "%"
                    accent: hud.severity(hud.weeklyPct)
                    valueColor: hud.severity(hud.weeklyPct)
                    value: hud.weeklyPct.toFixed(0)
                    showBar: true; pct: hud.weeklyPct
                }
                Text {
                    text: hud.weeklyLimit ? ("resets in " + hud.fmtRemaining(hud.weeklyLimit.resetsAt)) : "--"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Item { width: 1; height: 2 }

                Text {
                    text: hud.fmtTokens(hud.usage.todayTotalTokens) + " tok today · " + (hud.usage.todayPrompts || 0) + " prompts"
                    color: "#446655"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            },

            Text {
                anchors { top: divider.bottom; left: parent.left; right: parent.right; margins: 14 }
                visible: !hud.ready
                wrapMode: Text.WordWrap
                text: hud.usage.authHelpText || "No usage data yet."
                color: "#446655"
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        ]

        // ============================================================
        // BACK — today's tokens by model
        // ============================================================
        back: [
            Text {
                id: backTitle
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /ai/claude.usage.today"
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
                    top: backDivider.bottom; left: parent.left; right: parent.right
                    topMargin: 14; leftMargin: 14; rightMargin: 14
                }
                spacing: 6

                Repeater {
                    model: hud.modelRows
                    delegate: Row {
                        width: parent.width
                        Text { width: 220; text: modelData.name; color: hud.fg; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        Text { text: hud.fmtTokens(modelData.tokens); color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.fontFamily; font.pixelSize: 12 }
                    }
                }

                Text {
                    visible: hud.modelRows.length === 0
                    text: "No usage recorded today."
                    color: "#446655"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Text { text: "poll 60s · via omarchy-agent-usage-claude"; color: "#446655"; font.family: Theme.fontFamily; font.pixelSize: 12 }
            }
        ]
    }
}
