// One launcher button: a glyph icon over a small letter-spaced label on a
// rounded bordered tile. Flat synthwave styling — Stage 1 has NO glow; the
// icon/label each live in their own Item so a Glow/MultiEffect source can be
// attached in Stage 2 without changing layout. Runs `command` via bash -lc on
// click (like SteamRestore). `active` drives the toggled-on look (WORK/HOME/
// NIGHT). Mirrors `.launch-btn` from the eww eww.scss.
//
//     LaunchButton {
//         icon: ""                       // nf glyph
//         label: "WORK"
//         command: "~/.config/eww/scripts/launch.sh ..."
//         active: modeState.value === "work"   // optional
//     }

import QtQuick
import Quickshell.Io
import "../theme"

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string command: ""
    property bool active: false

    property bool hovered: false

    implicitWidth:  Math.max(84, col.implicitWidth + 28)   // min-width 84 from SCSS
    implicitHeight: col.implicitHeight + 16
    radius: 10
    color: hovered ? Theme.hoverFill : (active ? Theme.activeFill : "transparent")
    border.width: 2
    border.color: (hovered || active) ? Theme.cyan : Theme.magentaDim

    Behavior on color        { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Toggled-on flips the accents: icon → magenta, label → cyan.
    readonly property color iconColor:  active ? Theme.magenta : Theme.cyan
    readonly property color labelColor: active ? Theme.cyan    : Theme.magenta

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 2

        // Icon. Wrapped in an Item sized to the glyph so centering is decoupled
        // from the Font-Awesome left-bearing (eww nudged with margin-right:6px).
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth:  glyph.implicitWidth
            implicitHeight: glyph.implicitHeight
            Text {
                id: glyph
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -3
                text: root.icon
                color: root.iconColor
                font.family: Theme.fontFamily
                font.pixelSize: 28
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth:  lbl.implicitWidth
            implicitHeight: lbl.implicitHeight
            Text {
                id: lbl
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label
                color: root.labelColor
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 3
                font.bold: true
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: { proc.command = ["bash", "-lc", root.command]; proc.running = true }
    }

    Process { id: proc; running: false }
}
