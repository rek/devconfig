// Top processes by CPU% — off by default. Constantly-reordering process
// lists are distracting sitting next to the other glanceable HUDs, so this
// only polls at the fast interval while the front's LIVE toggle is on; off
// falls back to a slow 100s background refresh so the snapshot stays roughly
// current without the re-sort flicker. Row count and poll interval are
// back-face settings, each an OptionList (click the value you want directly,
// not a "cycle to next" pill).
// Pass `anchorBelow` to hang its top edge directly off another card's
// bottom (same convention as IssuesHud) and `rightMargin` to park it in its
// own column — e.g. a second inner column left of DiskHud, since eww's
// claude-hud already owns the bottom-right corner further down the screen.
//
// Data comes from scripts/top-procs.sh -> one "pid|cpu|mem|name" line per
// process, top 15 by %CPU (this HUD slices to however many rows it wants).

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

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
    WlrLayershell.namespace: "qs-topcpu-hud"

    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

    // Even when LIVE is off, keep refreshing at a slow 100s cadence so the
    // frozen snapshot doesn't go stale for hours — just no fast re-sort flicker.
    Poller {
        id: topProc
        command: "~/.config/quickshell/scripts/top-procs.sh"
        interval: live.value ? (parseFloat(intervalSetting.value) || 3) * 1000 : 100000
    }
    // One snapshot on load regardless of the LIVE setting, so a freshly
    // started, paused-by-default card isn't just blank.
    Component.onCompleted: topProc.refresh()

    readonly property var allRows: (topProc.value || "").split("\n")
        .filter(l => l.length > 0)
        .map(l => { const p = l.split("|"); return { pid: p[0], cpu: parseFloat(p[1]) || 0, mem: p[2] || "0", name: p[3] || "?" }; })
    readonly property int count: parseInt(countSetting.value) || 5
    readonly property var rows: allRows.slice(0, count)

    readonly property color fg: live.value ? "#00ff88" : "#446655"

    function shortName(n) {
        return n.length > 16 ? n.substring(0, 15) + "…" : n;
    }

    // Exposed so a sibling HUD can stack directly under this one and track
    // its height as the row-count setting resizes it (same anchorBelow
    // convention as IssuesHud).
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
        cardHeight: 74 + hud.count * 28
        Behavior on cardHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        borderColor: hud.fg
        background: "#b8070b08"
        clickFrontToFlip: false
        dragToFlip: true

        // ============================================================
        // FRONT — top-N by CPU%
        // ============================================================
        front: [
            Text {
                id: title
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /proc/top_cpu"
                color: hud.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
            },

            ToggleButton {
                id: live
                anchors { top: parent.top; right: parent.right; margins: 14 }
                stateName: "topcpu-live"
                initial: "off"
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

            Column {
                anchors {
                    top: divider.bottom; left: parent.left; right: parent.right
                    topMargin: 10; leftMargin: 14; rightMargin: 14
                }
                spacing: 6

                Repeater {
                    model: hud.rows
                    delegate: StatRow {
                        width: parent.width
                        accent: hud.fg
                        label: hud.shortName(modelData.name)
                        value: modelData.cpu.toFixed(1)
                        suffix: "%"
                        showBar: true
                        pct: modelData.cpu
                    }
                }
            }
        ]

        // ============================================================
        // BACK — row count + live-update toggle
        // ============================================================
        back: [
            Text {
                id: backTitle
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /proc/top_cpu.settings"
                color: hud.fg
                font.family: "JetBrainsMono Nerd Font"
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
                    topMargin: 16; leftMargin: 14
                }
                spacing: 14

                Column {
                    spacing: 6
                    Text {
                        text: "SHOW"
                        color: "#7fffaf"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    OptionList {
                        id: countSetting
                        stateName: "topcpu-count"
                        options: ["5", "10", "15"]
                        suffix: " ROWS"
                        accent: hud.fg
                    }
                }

                Column {
                    spacing: 6
                    Text {
                        text: "POLL EVERY"
                        color: "#7fffaf"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    OptionList {
                        id: intervalSetting
                        stateName: "topcpu-interval"
                        options: ["1s", "3s", "5s", "10s"]
                        initial: "3s"
                        accent: hud.fg
                    }
                }

                Text {
                    text: "LIVE toggle is on the front, top-right"
                    color: "#446655"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
                Text {
                    text: "off = frozen snapshot, no re-sort flicker"
                    color: "#446655"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }
        ]
    }
}
