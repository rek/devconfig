// Persisted segmented option picker — a row of pills, one per option, click
// any one directly to select it (unlike CycleButton-style "click to advance
// to the next value").
//
//     OptionList {
//         stateName: "topcpu-count"
//         options: ["5", "10", "15"]
//         suffix: " ROWS"
//     }
//
// State persists to ~/.local/state/quickshell-<stateName>. Read on startup,
// written on every click.

import QtQuick
import Quickshell.Io

Row {
    id: root

    // === Public API ===

    property var options: []
    property string stateName: "optionlist"
    property string prefix: ""
    property string suffix: ""
    property string initial: options.length ? options[0] : ""

    property string value: initial

    // Theming.
    property color accent:   "#00ff88"
    property color dim:      "#3a8a5a"
    property color fillOn:   "#1a3322"
    property color fillHover: "#12241c"
    property string fontFamily: "JetBrainsMono Nerd Font"

    spacing: 6

    Repeater {
        model: root.options

        delegate: Rectangle {
            id: pill
            property bool selected: modelData === root.value
            property bool hovered: false

            width:  pillLabel.implicitWidth + 12
            height: pillLabel.implicitHeight + 6
            radius: 3
            color: selected ? root.fillOn : (hovered ? root.fillHover : "transparent")
            border.color: selected || hovered ? root.accent : root.dim
            border.width: 1

            Text {
                id: pillLabel
                anchors.centerIn: parent
                text: root.prefix + modelData + root.suffix
                color: pill.selected ? root.accent : root.dim
                font.family: root.fontFamily
                font.pixelSize: 10
                font.bold: pill.selected
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.select(modelData)
                onEntered: pill.hovered = true
                onExited:  pill.hovered = false
            }
        }
    }

    // === Behavior ===

    function select(v) {
        root.value = v;
        writeProc.command = [
            "sh", "-c",
            "mkdir -p ~/.local/state && printf '%s' '"
            + v
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
            onStreamFinished: {
                const v = text.trim();
                if (root.options.indexOf(v) !== -1) root.value = v;
            }
        }
    }

    Process {
        id: writeProc
        running: false
    }
}
