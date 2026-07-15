// Lily58 split-keyboard status: link (USB/BLE/off) + battery percent of each
// half, styled as a spinning mixtape — a reel per half, "SIDE A/B" reading
// the link state. Top-right; pass `anchorBelow` (e.g. statsHud) to hang its
// top edge directly off another card's bottom, same convention as IssuesHud.
// Swipe/drag the card to flip it over; the back holds raw diagnostics plus
// the ZMK Studio launcher that used to live on a front-click (moved back so
// drag-to-flip and click don't fight).
//
// Data comes from scripts/keyboard-state.sh -> "link|Lpct|Rpct" (see script
// header for the BLE battery-proxy details).

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

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-keyboard-hud"

    // Click-through everywhere except the card itself.
    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

    Poller {
        id: kb
        command: "~/.config/quickshell/scripts/keyboard-state.sh"
        interval: 15000
    }

    readonly property var parts: (kb.value || "off|--|--").split("|")
    readonly property string link: parts[0] || "off"
    readonly property string lpct: parts[1] || "--"
    readonly property string rpct: parts[2] || "--"
    readonly property bool up: link !== "off"
    // nf-md-usb / nf-md-bluetooth / nf-md-keyboard_off
    readonly property string linkGlyph: link === "usb" ? "󰈷"
                                      : link === "ble" ? "󰂯"
                                      :                  "󰌐"
    readonly property color fg: up ? "#00ff88" : "#446655"

    // Same anchorBelow convention as IssuesHud/PrsHud/DiskHud.
    readonly property real cardTopY:
        hud.anchorBelow ? (hud.anchorBelow.cardBottomY + hud.anchorGap)
                        : (hud.height * 0.35 + 123 + 20)
    readonly property real cardBottomY: cardTopY + card.cardHeight

    Process { id: proc; running: false }

    FlipCard {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.topMargin: hud.cardTopY
        cardWidth: 380
        cardHeight: 220
        borderColor: hud.fg
        background: "#b8070b08"
        clickFrontToFlip: false
        dragToFlip: true

        // ============================================================
        // FRONT — spinning reels, one per half
        // ============================================================
        front: [
            Text {
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /media/keeb.tape"
                color: hud.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
            },

            Text {
                anchors { top: parent.top; right: parent.right; margins: 14 }
                text: hud.linkGlyph + " " + hud.link.toUpperCase()
                color: hud.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            },

            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 6
                spacing: 60

                CassetteReel { tag: "L"; pct: hud.lpct; spinning: hud.up; accent: hud.fg }
                CassetteReel { tag: "R"; pct: hud.rpct; spinning: hud.up; accent: hud.fg }
            },

            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 10 }
                text: "SIDE " + (hud.link === "usb" ? "A · wired" : hud.link === "ble" ? "B · wireless" : "— stopped")
                color: Qt.rgba(hud.fg.r, hud.fg.g, hud.fg.b, 0.6)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.letterSpacing: 1
            }
        ]

        // ============================================================
        // BACK — raw diagnostics + the ZMK Studio dev-server launcher
        // ============================================================
        back: [
            Text {
                id: backTitle
                anchors { top: parent.top; left: parent.left; margins: 14 }
                text: "▌ /media/keeb.diag"
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
                    top: backDivider.bottom; left: parent.left; right: parent.right
                    topMargin: 12; leftMargin: 14; rightMargin: 14
                }
                spacing: 5

                Text { text: "mac   E8:0C:B3:F6:66:10"; color: hud.fg; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "svc   battery1 (0x180f)";  color: hud.fg; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "char  2a19 (right proxy)"; color: hud.fg; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "poll  every 15s";          color: hud.fg; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                Text { text: "link  " + hud.link;        color: hud.fg; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
            },

            IconButton {
                anchors { bottom: parent.bottom; right: parent.right; margins: 14 }
                icon: "󰏌"
                label: "ZMK STUDIO"
                accent: hud.fg
                onClicked: {
                    proc.command = ["bash", "-lc", "xdg-open http://localhost:5173"];
                    proc.running = true;
                }
            }
        ]
    }
}
