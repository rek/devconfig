// One PR/issue line: #N  title…  [🤖] [🔗] ci-icon. Click the row to open
// the URL in the browser; click 🔗 to copy the URL to the clipboard; click
// 🤖 to focus the project's zellij tab in Alacritty and spawn a fresh pane
// running `claude` with a "read new comments on this gh issue: <url>"
// prompt as its first message.
//
//     PrItem { prNum: 42; title: "fix login"; url: "..."; ci: "pass" }
//     PrItem { prNum: 7;  title: "bug";       url: "..."; showCi: false; showLink: true
//              showTab: true; tabName: "alpha" }

import QtQuick
import Quickshell.Io

Item {
    id: root

    // === Public API ===
    property int    prNum: 0
    property string title: ""
    property string url:  ""
    property string ci:   "none"      // "pass" | "fail" | "pending" | "none"
    property bool   showCi: true      // hide CI dot when the row isn't a PR
    property bool   showLink: false   // show a borderless 🔗 button on the right
    property bool   showTab: false    // show a borderless 🤖 button on the right
    property string tabName: ""       // zellij tab to focus when 🤖 is clicked

    // Theming.
    property color accent:     "#00ff88"
    property color dim:        "#3a8a5a"
    property color titleColor: "#7fffaf"
    property string fontFamily: "JetBrainsMono Nerd Font"

    width: parent ? parent.width : 0
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse ? "#143322" : "transparent"
        radius: 3
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // Row-level click → open URL. Declared HERE (before the buttons) so the
    // emoji buttons declared further down stack on top and get their own
    // clicks; otherwise this MouseArea would be topmost and eat everything.
    MouseArea {
        id: hover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: if (root.url) Qt.openUrlExternally(root.url)
    }

    Text {
        id: numLabel
        anchors {
            left: parent.left
            leftMargin: 4
            verticalCenter: parent.verticalCenter
        }
        text: "#" + root.prNum
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        id: ciLabel
        visible: root.showCi
        anchors {
            right: parent.right
            rightMargin: 6
            verticalCenter: parent.verticalCenter
        }
        text: root.ci === "pass"    ? "✓"
            : root.ci === "fail"    ? "✗"
            : root.ci === "pending" ? "●"
            :                         "·"
        color: root.ci === "pass"    ? "#7fffaf"
             : root.ci === "fail"    ? "#ff5555"
             : root.ci === "pending" ? "#ffd166"
             :                         root.dim
        font.family: root.fontFamily
        font.pixelSize: 12
        font.bold: true
    }

    // --- Copy-link button. No background, no border — just the emoji.
    // Copies root.url to the Wayland clipboard via wl-copy. The inner
    // MouseArea sits above the row's, so the row's open-in-browser action
    // doesn't also fire.
    Item {
        id: linkBtn
        visible: root.showLink
        anchors {
            right: ciLabel.visible ? ciLabel.left : parent.right
            rightMargin: 6
            verticalCenter: parent.verticalCenter
        }
        width: linkLabel.implicitWidth + 6
        height: linkLabel.implicitHeight + 4

        Text {
            id: linkLabel
            anchors.centerIn: parent
            text: linkCopied.running ? "✓" : "🔗"
            opacity: linkHover.containsMouse || linkCopied.running ? 1.0 : 0.55
            font.pixelSize: 12
        }

        Process {
            id: copyProc
            command: ["wl-copy", root.url]
            running: false
            onExited: linkCopied.restart()
        }

        // Briefly flash a ✓ to confirm the copy.
        Timer {
            id: linkCopied
            interval: 900
            repeat: false
        }

        MouseArea {
            id: linkHover
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: if (root.url) copyProc.running = true
        }
    }

    // --- Open-in-zellij-tab button. Sits to the LEFT of the 🔗 button.
    // Fires the open-project-tab.sh helper, which raises Alacritty and either
    // switches to an existing tab or creates one running `claude`.
    Item {
        id: tabBtn
        visible: root.showTab && root.tabName !== ""
        anchors {
            right: linkBtn.visible ? linkBtn.left
                 : (ciLabel.visible ? ciLabel.left : parent.right)
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        width: tabLabel.implicitWidth + 6
        height: tabLabel.implicitHeight + 4

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: "🤖"
            opacity: tabHover.containsMouse ? 1.0 : 0.55
            font.pixelSize: 12
        }

        // bash -lc 'script "$1" "$2"' _ tabName url  →  positional args sidestep
        // shell escaping for the URL.
        Process {
            id: tabProc
            command: ["bash", "-lc",
                "$HOME/dev/qs-prototype/scripts/issue-to-claude.sh \"$1\" \"$2\"",
                "_", root.tabName, root.url]
            running: false
        }

        MouseArea {
            id: tabHover
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: tabProc.running = true
        }
    }

    Text {
        anchors {
            left: numLabel.right
            right: tabBtn.visible ? tabBtn.left
                 : (linkBtn.visible ? linkBtn.left
                 : (ciLabel.visible ? ciLabel.left : parent.right))
            leftMargin: 8
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text: root.title
        color: root.titleColor
        font.family: root.fontFamily
        font.pixelSize: 11
        elide: Text.ElideRight
    }
}
