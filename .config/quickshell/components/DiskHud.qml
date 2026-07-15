// Disk usage — two spinning "disk" gauges (root volume + /boot), styled
// after gallery variant #22 (Vinyl Record): a literal disk for disk space.
// Continues the media-rack bit started by KeyboardHud's cassette tape.
// Top-right; pass `anchorBelow` (e.g. ScopeHud) to hang its top edge
// directly off another card's bottom, same convention as IssuesHud. Drag
// to flip for raw df diagnostics.
//
// Data comes from scripts/disk-usage.sh ->
// "rootPct|rootUsed|rootSize|rootAvail|bootPct|bootUsed|bootSize|bootAvail".

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: hud

    property var anchorBelow: null
    property int anchorGap: 20

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
    WlrLayershell.namespace: "qs-disk-hud"

    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

    Poller {
        id: disk
        command: "~/.config/quickshell/scripts/disk-usage.sh"
        interval: 30000
    }

    readonly property var parts: (disk.value || "0|--|--|--|0|--|--|--").split("|")
    readonly property real rootPct:   parseFloat(parts[0]) || 0
    readonly property string rootUsed:  parts[1] || "--"
    readonly property string rootSize:  parts[2] || "--"
    readonly property string rootAvail: parts[3] || "--"
    readonly property real bootPct:   parseFloat(parts[4]) || 0
    readonly property string bootUsed:  parts[5] || "--"
    readonly property string bootSize:  parts[6] || "--"
    readonly property string bootAvail: parts[7] || "--"

    // Green under 70%, amber under 90%, red beyond — same severity read as
    // the battery-level widgets, repurposed for "running out of room."
    function severity(pct) {
        if (pct >= 90) return "#ff4d4d";
        if (pct >= 70) return "#ffb000";
        return "#00ff88";
    }

    // Both gauges spin together on hover anywhere over the card, not just
    // when hovering a disc individually.
    property bool cardHovered: false

    // Same anchorBelow convention as IssuesHud/PrsHud — falls back to the
    // old fixed-offset guess (statsCard's own old center formula) if used
    // standalone with no anchorBelow given.
    readonly property real cardTopY:
        hud.anchorBelow ? (hud.anchorBelow.cardBottomY + hud.anchorGap)
                        : (hud.height * 0.35 - 143 - 232)
    readonly property real cardBottomY: cardTopY + card.cardHeight

    FlipCard {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.topMargin: hud.cardTopY
        cardWidth: 380
        cardHeight: 232
        borderColor: hud.severity(Math.max(hud.rootPct, hud.bootPct))
        background: "#b8070b08"
        clickFrontToFlip: false
        dragToFlip: true

        // ============================================================
        // FRONT — spinning disk gauges
        // ============================================================
        front: [
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: hud.cardHovered = true
                onExited:  hud.cardHovered = false
            },

            Text {
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /dev/disk.usage"
                color: hud.severity(Math.max(hud.rootPct, hud.bootPct))
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
            },

            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 8
                spacing: 60

                Column {
                    spacing: 4
                    VinylGauge { anchors.horizontalCenter: parent.horizontalCenter; tag: "ROOT"; pct: hud.rootPct; accent: hud.severity(hud.rootPct); spinning: hud.cardHovered }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: hud.rootAvail + " free"
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }
                Column {
                    spacing: 4
                    VinylGauge { anchors.horizontalCenter: parent.horizontalCenter; tag: "BOOT"; pct: hud.bootPct; accent: hud.severity(hud.bootPct); spinning: hud.cardHovered }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: hud.bootAvail + " free"
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }
            }
        ]

        // ============================================================
        // BACK — raw df diagnostics
        // ============================================================
        back: [
            Text {
                id: backTitle
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /dev/disk.diag"
                color: hud.severity(Math.max(hud.rootPct, hud.bootPct))
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
                    top: backDivider.bottom; left: parent.left; right: parent.right
                    topMargin: 12; leftMargin: 14; rightMargin: 14
                }
                spacing: 5

                Text { text: "/     (root)  " + Math.round(hud.rootPct) + "%  " + hud.rootUsed + " used / " + hud.rootSize + "  (" + hud.rootAvail + " free)"; color: hud.severity(hud.rootPct); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "        also covers /home, pacman cache, /var/log"; color: "#446655"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                Text { text: "/boot (nvme)  " + Math.round(hud.bootPct) + "%  " + hud.bootUsed + " used / " + hud.bootSize + "  (" + hud.bootAvail + " free)"; color: hud.severity(hud.bootPct); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "poll  every 30s"; color: "#446655"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
            }
        ]
    }
}
