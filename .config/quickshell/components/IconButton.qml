// One-shot icon button. No state, no persistence — just an icon, hover
// highlight, and a `clicked` signal.
//
//     IconButton {
//         icon: ""                       // nf-md-refresh
//         onClicked: refreshSomething()
//     }

import QtQuick

Rectangle {
    id: root

    property string icon:  ""
    property string label: ""   // optional text to the right of the icon
    property color accent: "#00ff88"
    property color dim:    "#3a8a5a"
    property color fillHover: "#1a3322"
    property string fontFamily: "JetBrainsMono Nerd Font"

    signal clicked()

    width:  iconLabel.implicitWidth + 14
    height: iconLabel.implicitHeight + 6
    radius: 3
    color: hovered ? fillHover : "transparent"
    border.color: hovered ? accent : dim
    border.width: 1

    property bool hovered: false

    Text {
        id: iconLabel
        anchors.centerIn: parent
        text: root.icon + (root.label ? " " + root.label : "")
        color: root.hovered ? root.accent : root.dim
        font.family: root.fontFamily
        font.pixelSize: 10
        font.bold: root.hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
        onEntered: root.hovered = true
        onExited:  root.hovered = false
    }
}
