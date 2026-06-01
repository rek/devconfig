// Single stat row for a HUD card: LABEL  [optional bar]  VALUE.
//
//     StatRow { label: "CPU"; value: cpuPct; suffix: "%"; showBar: true; pct: cpuPct }
//     StatRow { label: "TMP"; value: tmp;    suffix: "°C" }
//
// Width fills its parent; height is fixed. Drop into a Column for a stack.

import QtQuick

Item {
    id: root

    // === Public API ===

    property string label: ""
    property string value: ""
    property string suffix: ""
    property bool   showBar: false
    property real   pct: 0          // 0..100, drives the bar fill

    // Theming. Match the PinToggle defaults so a HUD reads as one piece.
    property color accent:     "#00ff88"
    property color valueColor: "#7fffaf"
    property string fontFamily: "JetBrainsMono Nerd Font"

    // === Layout ===

    implicitHeight: 22
    width: parent ? parent.width : 0

    Text {
        id: lbl
        text: root.label
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: 12
        font.bold: true
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: barFrame
        visible: root.showBar
        anchors {
            left: lbl.right
            leftMargin: 14
            right: valText.left
            rightMargin: 14
            verticalCenter: parent.verticalCenter
        }
        height: 8
        color: "transparent"
        border.color: root.accent
        border.width: 1

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: 2
            }
            width: Math.max(0, (barFrame.width - 4) * Math.min(100, Math.max(0, root.pct)) / 100)
            color: root.accent
            Behavior on width {
                NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
            }
        }
    }

    Text {
        id: valText
        text: root.value + root.suffix
        color: root.valueColor
        font.family: root.fontFamily
        font.pixelSize: 12
        font.bold: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
