// One-click launcher for Blender. Sits immediately left of the Orca Slicer
// button, bottom-right of eDP-2, matching its size/style. Launches with
// -noaudio since this machine's WirePlumber sink-gating deadlocks Blender's
// audio backend on startup (see headphone-toggle.sh for the underlying issue).

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
    WlrLayershell.namespace: "qs-blender-launch"

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

    function launch() {
        proc.command = ["bash", "-lc",
            "~/.config/eww/scripts/launch.sh uwsm-app -- blender -noaudio"];
        proc.running = true;
        hud.flash = true;
        flashOff.restart();
    }

    Rectangle {
        id: btn
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 140   // 82 (Orca's margin) + 46 (Orca's width) + 12 gap
            bottomMargin: 560
        }
        width: 46
        height: 46
        radius: 6
        color: (mouse.containsMouse || hud.flash) ? "#1a3322" : "#b8070b08"
        border.color: "#00ff88"
        border.width: 2

        // nf-md-blender
        Text {
            anchors.centerIn: parent
            text: "󰳫"
            color: "#00ff88"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hud.launch()
        }
    }
}
