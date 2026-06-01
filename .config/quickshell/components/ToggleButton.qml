// Persisted boolean toggle pill. Same shape as PinToggle was — but the icons
// and label are configurable so it works for any on/off control (pin, watch,
// mute, etc).
//
//     ToggleButton {                       // pin-on-top
//         id: pin
//         stateName: "stats-pin"
//         label: "PIN"
//         iconOn:  " "                   // nf-md-pin
//         iconOff: " "                   // nf-md-pin_off
//     }
//
//     ToggleButton {                       // watch (icon-only, default-on)
//         id: watch
//         stateName: "prs-watch"
//         initial: "on"
//         iconOn:  ""                     // nf-md-eye
//         iconOff: ""                     // nf-md-eye_off
//     }
//
// State persists to ~/.local/state/quickshell-<stateName>. Read on startup,
// written on every click.

import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    // === Public API ===

    property string stateName: "toggle"
    property string label: ""             // empty = icon-only pill
    property string iconOn:  ""
    property string iconOff: ""
    property string initial: "off"        // fallback when no state file exists

    property bool value: initial === "on"

    // Theming.
    property color accent: "#00ff88"
    property color dim:    "#3a8a5a"
    property color fillOn: "#1a3322"
    property string fontFamily: "JetBrainsMono Nerd Font"

    // === Visual ===

    width:  pillLabel.implicitWidth + 14
    height: pillLabel.implicitHeight + 6
    radius: 3
    color: value ? fillOn : "transparent"
    border.color: hovered ? accent : (value ? accent : dim)
    border.width: 1

    property bool hovered: false

    Text {
        id: pillLabel
        anchors.centerIn: parent
        text: (root.value ? root.iconOn : root.iconOff)
            + (root.label ? " " + root.label : "")
        color: root.value ? root.accent : root.dim
        font.family: root.fontFamily
        font.pixelSize: 10
        font.bold: root.value
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.toggle()
        onEntered: root.hovered = true
        onExited:  root.hovered = false
    }

    // === Behavior ===

    function toggle() {
        root.value = !root.value;
        writeProc.command = [
            "sh", "-c",
            "mkdir -p ~/.local/state && printf '%s' '"
            + (root.value ? "on" : "off")
            + "' > ~/.local/state/quickshell-" + root.stateName
        ];
        writeProc.running = true;
    }

    Component.onCompleted: readProc.running = true

    Process {
        id: readProc
        command: [
            "sh", "-c",
            "cat ~/.local/state/quickshell-" + root.stateName
            + " 2>/dev/null || echo " + root.initial
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.value = text.trim() === "on"
        }
    }

    Process {
        id: writeProc
        running: false
    }
}
