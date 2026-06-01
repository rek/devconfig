// Self-contained "my open PRs" HUD. Sibling to IssuesHud — same shape, but
// the rows carry CI status and the script returns PRs (not needs-reply
// issues). Polls every 60s while WATCH is on AND `active` is true.
//
//     PrsHud {
//         title:     "▌ /git/my_prs.tgt"
//         stateKey:  "prs"
//         script:    "~/.config/eww/scripts/github-prs.sh"
//         cachePath: "${XDG_RUNTIME_DIR:-/tmp}/eww-github-prs.json"
//         vCenterOffsetRel: -0.40
//         active: root.workMode               // gate visibility from caller
//     }
//
// When `active` flips to false the PanelWindow hides, the poller stops, and
// cardBottomY collapses to 0 so siblings using `anchorBelow: this` know to
// fall back to their own positioning.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: hud

    // === Public API ===
    property string script: "~/.config/eww/scripts/github-prs.sh"
    property string cachePath: "${XDG_RUNTIME_DIR:-/tmp}/eww-github-prs.json"
    property string title: "▌ /git/my_prs"
    property string stateKey: "prs"
    property string emptyText: "   no open prs   "
    property real   vCenterOffsetRel: -0.40
    property var    anchorBelow: null
    property int    anchorGap: 12
    property real   uiScale: 1.3
    // When false, hide the window entirely and stop polling. Siblings using
    // `anchorBelow: this` will see cardBottomY collapse to 0.
    property bool   active: true

    // Visual top edge of the card in panel coords. The Scale transform has its
    // origin at the card's top-left, so the scaled card's top stays at this y.
    // Computed explicitly (rather than read back from the anchor-resolved
    // card.y) so the cross-window stacking chain is robust to layout timing.
    readonly property real cardTopY:
        hud.anchorBelow ? (hud.anchorBelow.cardBottomY + hud.anchorGap)
                        : (hud.height * (0.5 + hud.vCenterOffsetRel)
                           - card.height * hud.uiScale / 2)

    readonly property real cardBottomY:
        active ? (cardTopY + card.height * uiScale) : 0

    visible: active

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

    WlrLayershell.layer: pin.value ? WlrLayer.Overlay : WlrLayer.Bottom
    WlrLayershell.namespace: "qs-prshud-" + hud.stateKey

    mask: Region {
        x: card.x
        y: card.y
        width: card.width * hud.uiScale
        height: card.height * hud.uiScale
    }

    Poller {
        id: poll
        command: hud.script
        interval: 60000
        running: watch.value && hud.active
    }

    Process {
        id: refreshProc
        command: ["bash", "-c", 'rm -f "$1" 2>/dev/null', "_", hud.cachePath]
        running: false
        onExited: poll.refresh()
    }

    property var prList: {
        if (!poll.value) return [];
        try { return JSON.parse(poll.value); }
        catch (e) { return []; }
    }

    Rectangle {
        id: card
        anchors {
            left: parent.left
            leftMargin: 24
            top: parent.top
            topMargin: hud.cardTopY
        }
        width: 380
        height: watch.value
            ? 50 + Math.max(1, hud.prList.length) * 24 + 14
            : 50
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        transform: Scale {
            origin.x: 0; origin.y: 0
            xScale: hud.uiScale
            yScale: hud.uiScale
        }

        radius: 6
        color: "#b8070b08"
        border.color: "#00ff88"
        border.width: 2

        Text {
            id: titleText
            anchors {
                top: parent.top
                left: parent.left
                margins: 14
            }
            text: hud.title
            color: "#00ff88"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
        }

        Row {
            anchors {
                top: parent.top
                right: parent.right
                margins: 14
            }
            spacing: 8

            Text {
                visible: watch.value
                text: "● " + hud.prList.length
                color: "#00ff88"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
                visible: watch.value
                icon: ""                   // nf-md-refresh
                label: "SYNC"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: refreshProc.running = true
            }

            ToggleButton {
                id: watch
                stateName: hud.stateKey + "-watch"
                initial: "on"
                label:   "WATCH"
                iconOn:  ""                // nf-md-eye
                iconOff: ""                // nf-md-eye_off
                anchors.verticalCenter: parent.verticalCenter
            }

            ToggleButton {
                id: pin
                stateName: hud.stateKey + "-pin"
                label: "PIN"
                iconOn:  ""                // nf-md-pin
                iconOff: ""                // nf-md-pin_off
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            id: divider
            visible: watch.value
            anchors {
                top: titleText.bottom
                left: parent.left
                right: parent.right
                topMargin: 10
                leftMargin: 14
                rightMargin: 14
            }
            height: 1
            color: "#1a3322"
        }

        Column {
            visible: watch.value
            anchors {
                top: divider.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: 8
                leftMargin: 10
                rightMargin: 10
                bottomMargin: 10
            }
            spacing: 2

            Text {
                visible: hud.prList.length === 0
                text: hud.emptyText
                color: "#3a8a5a"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 4
            }

            Repeater {
                model: hud.prList
                delegate: PrItem {
                    prNum: modelData.number
                    title: modelData.title
                    url:   modelData.url
                    ci:    modelData.ci
                    showCi: true
                }
            }
        }
    }
}
