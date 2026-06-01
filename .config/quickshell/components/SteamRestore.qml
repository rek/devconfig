// One-click rescue for Steam windows that drift off-screen onto the glasses.
// Steam on Wayland remembers stale coords and parks its windows outside any
// monitor — they look minimized/lost. Clicking STEAM runs
// restore-steam-windows.sh, which clamps every steam window back inside the
// XREAL glasses' visible area and raises it.
//
// Lives bottom-right of eDP-2, just above the ddterm toggle. Sits on the
// Bottom layer (tucked behind windows) like the other HUDs.

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

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-steam-restore"

    // Click-through everywhere except the button itself.
    mask: Region {
        x: btn.x
        y: btn.y
        width: btn.width
        height: btn.height
    }

    Process { id: proc; running: false }

    // Brief "done" flash after a click so the press registers visually.
    property bool flash: false
    Timer { id: flashOff; interval: 600; onTriggered: hud.flash = false }

    function restore() {
        proc.command = ["bash", "-lc",
            "~/.config/hypr/scripts/restore-steam-windows.sh"];
        proc.running = true;
        hud.flash = true;
        flashOff.restart();
    }

    Rectangle {
        id: btn
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 24
            bottomMargin: 560
        }
        width: 46
        height: 46
        radius: 6
        color: (mouse.containsMouse || hud.flash) ? "#1a3322" : "#b8070b08"
        border.color: "#00ff88"
        border.width: 2

        // nf-md-restart on press (flash), steam glyph at rest.
        Text {
            anchors.centerIn: parent
            text: hud.flash ? "" : ""
            color: "#00ff88"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hud.restore()
        }
    }
}
