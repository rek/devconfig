// A bordered frame around a row of LaunchButtons, with a tag sitting on the
// top edge — reads as "these buttons are one either-or choice".
//
//     ButtonGroup {
//         title: "AUDIO OUT"
//         LaunchButton { ... }
//         LaunchButton { ... }
//     }
//
// Children go straight into the inner Row. The tag's background is
// Theme.panel so it cuts the frame line cleanly on the launcher panel.

import QtQuick
import "../theme"

Rectangle {
    id: root

    property string title: ""
    property color accent: Theme.cyan
    default property alias content: row.data

    implicitWidth:  row.implicitWidth + 16
    implicitHeight: row.implicitHeight + 16
    radius: 14
    color: "transparent"
    border.width: 1
    border.color: accent

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }

    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.top }
        width: tag.implicitWidth + 12; height: tag.implicitHeight + 2
        color: Theme.panel
        Text {
            id: tag
            anchors.centerIn: parent
            text: root.title
            color: root.accent
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.letterSpacing: 3
            font.bold: true
        }
    }
}
