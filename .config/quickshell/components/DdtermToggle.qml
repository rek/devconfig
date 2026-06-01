// Standalone dropdown-terminal monitor toggle for eDP-2. Segmented DP-1 / DP-2
// control mirroring pyprland's force_monitor, read straight from
// ~/.config/pypr/config.toml so the active pill always reflects truth. Clicking
// a pill runs ddterm-toggle-monitor.sh <connector>, which rewrites the toml and
// reloads pypr (no-op if already there).
//
// Replaces the old eww `ddterm-hud`; sits in the same spot — bottom-right of
// eDP-2, lifted clear of the Claude HUD.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: hud

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

    // Bottom layer (tucked behind windows) by default; PIN floats it to the
    // overlay so the pills are clickable above whatever's on screen.
    WlrLayershell.layer: pin.value ? WlrLayer.Overlay : WlrLayer.Bottom
    WlrLayershell.namespace: "qs-ddterm"

    mask: Region {
        x: card.x
        y: card.y
        width: card.width
        height: card.height
    }

    // Currently-forced connector ("DP-1" | "DP-2"), straight from the toml.
    Poller {
        id: mon
        command: "grep -E '^force_monitor' ~/.config/pypr/config.toml | sed -E 's/.*\"(.+)\".*/\\1/'"
        interval: 3000
        // Drop the optimistic override once the poll confirms the switch.
        onValueChanged: if (value === hud.pending) hud.pending = ""
    }

    // Optimistic selection: highlight the clicked pill immediately, before the
    // script + pypr reload land and the next poll catches up.
    property string pending: ""
    readonly property string current: pending !== "" ? pending : mon.value

    Process { id: setProc; running: false }
    Timer { id: confirmPoll; interval: 500; onTriggered: mon.refresh() }

    function setMonitor(conn) {
        if (conn === hud.current) return;
        hud.pending = conn;
        setProc.command = ["bash", "-lc",
            "~/.config/hypr/scripts/ddterm-toggle-monitor.sh " + conn];
        setProc.running = true;
        confirmPoll.restart();
    }

    Rectangle {
        id: card
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 24
            bottomMargin: 500
        }
        width: row.implicitWidth + 28
        height: row.implicitHeight + 16
        radius: 6
        color: "#b8070b08"
        border.color: "#00ff88"
        border.width: 2

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "TERM"
                color: "#3a8a5a"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: ["DP-1", "DP-2"]
                delegate: Rectangle {
                    id: seg
                    required property string modelData
                    readonly property bool active: hud.current === modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: segLabel.implicitWidth + 18
                    height: segLabel.implicitHeight + 8
                    radius: 4
                    color: active ? "#1a3322" : "transparent"
                    border.width: 1
                    border.color: (active || segMouse.containsMouse) ? "#00ff88" : "#3a8a5a"

                    Text {
                        id: segLabel
                        anchors.centerIn: parent
                        text: seg.modelData
                        color: seg.active ? "#00ff88" : "#3a8a5a"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: seg.active
                    }

                    MouseArea {
                        id: segMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hud.setMonitor(seg.modelData)
                    }
                }
            }

            ToggleButton {
                id: pin
                stateName: "ddterm-pin"
                label: "PIN"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
