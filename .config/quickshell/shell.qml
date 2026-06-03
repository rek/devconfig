// Quickshell HUDs on eDP-2: stats card (CPU/RAM/TMP/DL/UL/BAT), tgt PRs
// (work mode only), and needs-reply issues for alpha + parakeet. Runs
// alongside eww as a layer-shell client.
// Launch:   quickshell                  (auto-loads ~/.config/quickshell)
// Teardown: pkill quickshell

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"

ShellRoot {
    id: root

    // Active Hyprland mode ("work" | "home" | "none"). Used to gate which
    // HUDs are visible — the tgt PR HUD shows only in work mode.
    Poller {
        id: modeState
        command: "~/.config/eww/scripts/mode-state.sh"
        interval: 3000
    }
    readonly property bool workMode: modeState.value === "work"

    PanelWindow {
        id: statsHud

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

        // Click-through outside the card.
        mask: Region {
            x: card.x
            y: card.y
            width: card.width
            height: card.height
        }

        // === Metric pollers — same scripts the eww HUD uses. ===
        Poller { id: cpu;  command: "~/.config/eww/scripts/cpu.sh";        interval: 2000 }
        Poller { id: ram;  command: "free | awk '/Mem:/ {printf \"%.0f\", $3/$2 * 100}'"; interval: 2000 }
        Poller { id: tmp;  command: "~/.config/eww/scripts/cpu-temp.sh";   interval: 3000 }
        Poller { id: dl;   command: "~/.config/eww/scripts/net-dl.sh 1";   interval: 1000 }
        Poller { id: ul;   command: "~/.config/eww/scripts/net-ul.sh 1";   interval: 1000 }
        // Battery: combined "<pct>|<status>" e.g. "92|Not charging".
        Poller {
            id: bat
            command: "echo \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)|$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)\""
            interval: 10000
        }

        // Derived: parse the bat poller into a percent and a short status tag.
        property int    batPct: parseInt((bat.value || "").split("|")[0]) || 0
        property string batStatus: (bat.value || "").split("|")[1] || ""
        // CHG when actively charging, AC when plugged-but-stable, BAT on battery.
        property string batTag: batStatus === "Charging"           ? " CHG"
                              : batStatus === "Full"               ? " AC"
                              : batStatus === "Not charging"       ? " AC"
                              : batStatus === "Discharging"        ? " BAT"
                              :                                      ""

        Rectangle {
            id: card
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -parent.height * 0.15
            anchors.rightMargin: 24
            width: 380
            height: 246
            radius: 6
            // ARGB — ~72% alpha over near-black green-tinted backdrop.
            color: "#b8070b08"
            border.color: "#00ff88"
            border.width: 2

            // --- Header strip: title (left) + LIVE/PIN (right) ---
            Text {
                id: title
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: 14
                }
                text: "▌ /sys/proc.metrics"
                color: "#00ff88"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
            }

            Row {
                id: headerRight
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 14
                }
                spacing: 10

                Text {
                    text: "● LIVE"
                    color: "#00ff88"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 700 }
                        NumberAnimation { to: 1.00; duration: 700 }
                    }
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

            // --- Divider line below the header ---
            Rectangle {
                id: divider
                anchors {
                    top: title.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: 10
                    leftMargin: 14
                    rightMargin: 14
                }
                height: 1
                color: "#1a3322"
            }

            // --- Stat rows: CPU, RAM, TMP, DL, UL ---
            Column {
                anchors {
                    top: divider.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: 10
                    leftMargin: 14
                    rightMargin: 14
                    bottomMargin: 14
                }
                spacing: 6

                StatRow {
                    label: "CPU"; suffix: "%"
                    value: (parseInt(cpu.value) || 0).toString()
                    showBar: true
                    pct: parseInt(cpu.value) || 0
                }
                StatRow {
                    label: "RAM"; suffix: "%"
                    value: (parseInt(ram.value) || 0).toString()
                    showBar: true
                    pct: parseInt(ram.value) || 0
                }
                StatRow {
                    label: "TMP"; suffix: "°C"
                    value: tmp.value || "--"
                }
                StatRow {
                    label: "DL"; suffix: " MB/s"
                    value: dl.value || "0.00"
                }
                StatRow {
                    label: "UL"; suffix: " MB/s"
                    value: ul.value || "0.00"
                }
                StatRow {
                    label: "BAT"
                    suffix: "%" + statsHud.batTag
                    value: statsHud.batPct.toString()
                    showBar: true
                    pct: statsHud.batPct
                }
            }
        }
    }

    // ============================================================
    // tgt PR HUD — open PRs on maiella-io/tgt. Left edge of eDP-2, top of
    // the issues stack. Visible only in work mode; alphaIssues anchors
    // below it when it's up, and falls back to its own vCenterOffsetRel
    // when we're not in work mode.
    // ============================================================
    PrsHud {
        id: tgtPrs
        title:     "▌ /git/my_prs.tgt"
        stateKey:  "prs"
        script:    "~/.config/eww/scripts/github-prs.sh"
        cachePath: "${XDG_RUNTIME_DIR:-/tmp}/eww-github-prs.json"
        vCenterOffsetRel: -0.25
        active: root.workMode
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
        vCenterOffsetRel: -0.20
        // In work mode, slide below the tgt PR HUD. Otherwise fall back to
        // own vCenterOffsetRel — null tells the card to use verticalCenter.
        anchorBelow: tgtPrs.active ? tgtPrs : null
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
    // Synthwave launcher — two rows of action buttons, bottom-center of
    // eDP-2. Replaces the eww launcher; new magenta/cyan Theme singleton.
    // ============================================================
    Launcher {
        id: launcher
    }

}
