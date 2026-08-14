// Quickshell HUDs on eDP-2: stats card (CPU/RAM/TMP/DL/UL/BAT) and
// needs-reply issues for alpha + parakeet. Runs alongside eww as a
// layer-shell client.
// Launch:   quickshell                  (auto-loads ~/.config/quickshell)
// Teardown: pkill quickshell

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"

ShellRoot {
    id: root

    // ============================================================
    // Multi-channel oscilloscope — CPU/RAM/GPU, replacing eww's old top-hud
    // sparklines. Reclaims the freed-up top strip. Drag to flip for the git
    // commit heatmap that used to share that eww window.
    // ============================================================
    ScopeHud {
        id: scopeHud
    }

    PanelWindow {
        id: statsHud

        // Same anchorBelow convention as IssuesHud/PrsHud/DiskHud — hangs
        // directly off diskHud's bottom edge.
        property var anchorBelow: diskHud
        property int anchorGap: 20
        readonly property real cardTopY:
            anchorBelow ? (anchorBelow.cardBottomY + anchorGap)
                        : (height * 0.35 - statsCard.cardHeight / 2)
        readonly property real cardBottomY: cardTopY + statsCard.cardHeight

        screen: {
            for (let s of Quickshell.screens) {
                if (s.name === "eDP-2") return s;
            }
            return Quickshell.screens[0];
        }

        // Full-screen transparent layer; the visible card is positioned inside.
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusiveZone: 0
        color: "transparent"

        // Layer follows the ToggleButton inside the card. Bottom tucks the HUD
        // behind windows (eww-HUD default); Overlay floats above everything.
        WlrLayershell.layer: pin.value ? WlrLayer.Overlay : WlrLayer.Bottom
        WlrLayershell.namespace: "qs-devtest-stats"

        // Click-through outside the card. Tracks the flip card so the
        // clickable region covers it on either face.
        mask: Region {
            x: statsCard.x
            y: statsCard.y
            width: statsCard.width
            height: statsCard.height
        }

        // === Metric pollers — same scripts the eww HUD uses. ===
        // Same LIVE convention as TopCpuHud: the front toggle picks between the
        // fast per-metric cadence and a slow 100s background refresh, so turning
        // it off stops the constant sampling without leaving a stale card.
        // 15s across the board when LIVE — these are glanceable numbers, and
        // the old 1-3s cadence was a constant subprocess + repaint drip that
        // kept the compositor from ever idling. dl/ul still sample a 1s window
        // (the script's argument), so they're a snapshot every 15s, not an
        // average — brief transfers can slip between samples.
        readonly property int liveInterval: 15000
        readonly property int idleInterval: 100000
        Poller { id: cpu;  command: "~/.config/eww/scripts/cpu.sh";        interval: live.value ? statsHud.liveInterval : statsHud.idleInterval }
        Poller { id: ram;  command: "free | awk '/Mem:/ {printf \"%.0f\", $3/$2 * 100}'"; interval: live.value ? statsHud.liveInterval : statsHud.idleInterval }
        Poller { id: tmp;  command: "~/.config/eww/scripts/cpu-temp.sh";   interval: live.value ? statsHud.liveInterval : statsHud.idleInterval }
        Poller { id: dl;   command: "~/.config/eww/scripts/net-dl.sh 1";   interval: live.value ? statsHud.liveInterval : statsHud.idleInterval }
        Poller { id: ul;   command: "~/.config/eww/scripts/net-ul.sh 1";   interval: live.value ? statsHud.liveInterval : statsHud.idleInterval }
        // Battery: combined "<pct>|<status>" e.g. "92|Not charging".
        // Already slow, so LIVE doesn't slow it further — but pause it in step
        // with everything else when the card is off.
        Poller {
            id: bat
            command: "echo \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)|$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)\""
            interval: live.value ? 15000 : statsHud.idleInterval
        }

        readonly property color fg: live.value ? "#00ff88" : "#446655"

        // Derived: parse the bat poller into a percent and a short status tag.
        property int    batPct: parseInt((bat.value || "").split("|")[0]) || 0
        property string batStatus: (bat.value || "").split("|")[1] || ""
        // CHG when actively charging, AC when plugged-but-stable, BAT on battery.
        property string batTag: batStatus === "Charging"           ? " CHG"
                              : batStatus === "Full"               ? " AC"
                              : batStatus === "Not charging"       ? " AC"
                              : batStatus === "Discharging"        ? " BAT"
                              :                                      ""

        // Stats card. Front shows the metrics; clicking anywhere on it (or a
        // horizontal drag) turns it over to the settings back. The back's PIN
        // toggle keeps its own clicks, so the back flips home by drag only.
        FlipCard {
            id: statsCard
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: statsHud.cardTopY
            anchors.rightMargin: 24
            cardWidth: 380
            cardHeight: 246
            borderColor: statsHud.fg

            // ============================================================
            // FRONT — /sys/proc.metrics
            // ============================================================
            front: [
                Text {
                    id: title
                    anchors { top: parent.top; left: parent.left; margins: 14 }
                    text: "▌ /sys/proc.metrics"
                    color: statsHud.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                },

                // Was a decorative blinking "● LIVE" label; now the real
                // watch/pause control (its own MouseArea, so clicking it
                // doesn't fall through to the card's flip gesture).
                ToggleButton {
                    id: live
                    anchors { top: parent.top; right: parent.right; margins: 14 }
                    stateName: "stats-live"
                    initial: "on"
                    label: "LIVE"
                    iconOn:  ""
                    iconOff: ""
                    accent: statsHud.fg
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
                    spacing: 6

                    StatRow {
                        label: "CPU"; suffix: "%"
                        accent: statsHud.fg
                        value: (parseInt(cpu.value) || 0).toString()
                        showBar: true; pct: parseInt(cpu.value) || 0
                    }
                    StatRow {
                        label: "RAM"; suffix: "%"
                        accent: statsHud.fg
                        value: (parseInt(ram.value) || 0).toString()
                        showBar: true; pct: parseInt(ram.value) || 0
                    }
                    StatRow { label: "TMP"; suffix: "°C";    accent: statsHud.fg; value: tmp.value || "--" }
                    StatRow { label: "DL";  suffix: " MB/s"; accent: statsHud.fg; value: dl.value || "0.00" }
                    StatRow { label: "UL";  suffix: " MB/s"; accent: statsHud.fg; value: ul.value || "0.00" }
                    StatRow {
                        label: "BAT"
                        suffix: "%" + statsHud.batTag
                        accent: statsHud.fg
                        value: statsHud.batPct.toString()
                        showBar: true; pct: statsHud.batPct
                    }
                }
            ]

            // ============================================================
            // BACK — /sys/proc.settings
            // ============================================================
            back: [
                Text {
                    id: backTitle
                    anchors { top: parent.top; left: parent.left; margins: 14 }
                    text: "▌ /sys/proc.settings"
                    color: statsHud.fg
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

                // --- Settings rows. ---
                Column {
                    anchors {
                        top: backDivider.bottom; left: parent.left
                        topMargin: 14; leftMargin: 14
                    }
                    spacing: 14

                    Row {
                        spacing: 12

                        Text {
                            text: "PIN ON TOP"
                            color: "#7fffaf"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        ToggleButton {
                            id: pin
                            stateName: "stats-pin"
                            label: "PIN"
                            iconOn:  " "
                            iconOff: " "
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: "LIVE toggle is on the front, top-right"
                        color: "#446655"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                    Text {
                        text: "off = frozen snapshot, 100s background refresh"
                        color: "#446655"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                }
            ]
        }
    }

    // ============================================================
    // ISSUES HUDs — open issues whose last activity isn't from us.
    // Left edge of eDP-2; one card per repo, stacked vertically.
    // ============================================================
    IssuesHud {
        id: alphaIssues
        repo:    "rek/alphaTilesAgain"
        tabName: "alpha"
        title:   "▌ /git/needs_reply.atg"
        stateKey: "issues-alpha"
        anchorBelow: scopeHud
    }

    IssuesHud {
        repo:    "rek/parakeet"
        tabName: "parakeet"
        title:   "▌ /git/needs_reply.prk"
        stateKey: "issues-parakeet"
        anchorBelow: alphaIssues
    }

    // ============================================================
    // Dropdown-terminal monitor toggle (DP-1 / DP-2). Bottom-right of eDP-2,
    // where the old eww ddterm-hud lived. Mirrors pyprland's force_monitor.
    // ============================================================
    DdtermToggle {
        id: ddterm
    }

    // ============================================================
    // Steam window rescue button. One click drags off-screen Steam
    // windows back onto the glasses. Bottom-right of eDP-2, above ddterm.
    // ============================================================
    SteamRestore {
        id: steamRestore
    }

    // ============================================================
    // Orca Slicer launcher. Sits immediately left of the Steam button.
    // ============================================================
    OrcaSlicerLaunch {
        id: orcaSlicerLaunch
    }

    // ============================================================
    // Blender launcher. Sits immediately left of the Orca button.
    // Launches with -noaudio (see BlenderLaunch.qml).
    // ============================================================
    BlenderLaunch {
        id: blenderLaunch
    }

    // ============================================================
    // Disk usage — root volume + /boot, styled as spinning vinyl (gallery
    // variant #22). Top-right, hangs directly off the scope HUD's bottom
    // edge, top of the right-column stack. Drag to flip for raw df
    // diagnostics.
    // ============================================================
    DiskHud {
        id: diskHud
        anchorBelow: scopeHud
    }

    // ============================================================
    // Lily58 keyboard status — link (USB/BLE) + per-half battery, styled as
    // a spinning mixtape. Top-right, directly below the stats card; drag to
    // flip for diagnostics + the ZMK Studio launcher.
    // ============================================================
    KeyboardHud {
        id: keyboardHud
        anchorBelow: statsHud
    }

    // ============================================================
    // Top CPU / Top memory processes — a second inner column, immediately
    // left of DiskHud, hanging off the scope HUD's bottom edge like the
    // main right column does. NOT stacked below KeyboardHud (where they
    // used to live) — that column runs down into eww's claude-hud (fixed
    // bottom-right), and the two semi-transparent windows overlapping made
    // both unreadable. This column only needs to reach ~y680 at default
    // settings, nowhere near claude-hud's ~y1170 top edge.
    //
    // Off by default (back-face LIVE toggle) so the constantly-reordering
    // list doesn't sit there flickering; row count (5/10/15) is also a
    // back-face setting.
    // ============================================================
    TopCpuHud {
        id: topCpuHud
        anchorBelow: scopeHud
        rightMargin: 24 + 380 + 20   // DiskHud's width + a 20px gap
    }

    TopMemHud {
        id: topMemHud
        anchorBelow: topCpuHud
        rightMargin: topCpuHud.rightMargin
    }

    // ============================================================
    // Synthwave launcher — two rows of action buttons, bottom-center of
    // eDP-2. Replaces the eww launcher; new magenta/cyan Theme singleton.
    // ============================================================
    Launcher {
        id: launcher
    }

}
