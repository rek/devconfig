// Synthwave clock card — bottom-left of eDP-2. Port of the eww stats-hud
// header (brand row, big clock, date, uptime). The eww window's CPU/RAM/TMP/
// DL/UL rows are dropped (the stats card on the right shows them).
//
// Unlike the eww window, the input mask covers only the card, so it can no
// longer swallow clicks meant for the launcher beside it.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: hud

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
    WlrLayershell.namespace: "qs-clock"

    mask: Region {
        x: card.x; y: card.y; width: card.width; height: card.height
    }

    // Minute resolution, like the eww poll: a per-second repaint would keep
    // the compositor from ever idling.
    property date now: new Date()
    Timer {
        interval: 20000; running: true; repeat: true
        onTriggered: hud.now = new Date()
    }

    Poller { id: uptime; command: "uptime -p | sed 's/^up //'"; interval: 30000 }

    Rectangle {
        id: card
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 24; bottomMargin: 24 }
        width:  col.implicitWidth + 2 * 24
        height: col.implicitHeight + 2 * 18
        radius: 12
        color: Theme.panel
        border.color: Theme.magenta
        border.width: 2

        Column {
            id: col
            anchors.centerIn: parent
            spacing: 4

            Row {
                spacing: 10
                Text {
                    text: "◢ OUTRUN"
                    color: Theme.magenta
                    font.family: Theme.fontFamily
                    font.pixelSize: 14; font.bold: true; font.letterSpacing: 4
                }
                Text {
                    text: "// SYS NOMINAL"
                    color: Theme.cyan
                    font.family: Theme.fontFamily
                    font.pixelSize: 14; font.bold: true; font.letterSpacing: 3
                }
            }

            Text {
                text: Qt.formatDateTime(hud.now, "HH:mm")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 56; font.bold: true; font.letterSpacing: 6
            }

            Row {
                spacing: 20
                Text {
                    text: Qt.formatDateTime(hud.now, "ddd MMM dd  yyyy")
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: "▲ " + uptime.value
                    color: Theme.cyan
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }
    }
}
