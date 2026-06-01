// Self-contained "issues needing a reply" HUD. One PanelWindow on eDP-2,
// left-anchored, listing open issues whose last comment author != me.
//
//     IssuesHud {
//         repo:    "rek/alphaTilesAgain"
//         tabName: "alpha"
//         title:   "▌ /git/needs_reply.atg"
//         stateKey: "issues-alpha"        // must be unique per instance
//         vCenterOffsetRel: -0.20         // -0.5..+0.5 of screen height
//     }
//
// To stack a second hud directly under another, pass `anchorBelow` instead
// of vCenterOffsetRel. The lower hud tracks the upper one's card bottom in
// real time, so when WATCH toggles and the upper card resizes, the lower
// one slides to follow.
//
//     IssuesHud { id: top;  ...; vCenterOffsetRel: -0.20 }
//     IssuesHud { repo: ...; anchorBelow: top }
//
// `stateKey` is used as the unique prefix for ToggleButton state files AND
// the layer-shell namespace, so each HUD remembers its own WATCH/PIN state
// and doesn't collide with siblings.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: hud

    // === Public API ===
    property string repo: ""                    // e.g. "rek/alphaTilesAgain"
    property string tabName: ""                 // zellij tab for the 🤖 button
    property string title: "▌ /git/needs_reply" // header label
    property string stateKey: "issues"          // unique per instance
    property real   vCenterOffsetRel: -0.15     // vertical offset (frac of screen H)
    property var    anchorBelow: null           // another IssuesHud to stack under
    property int    anchorGap: 12               // gap below anchored hud (unscaled px)
    property real   uiScale: 1.3

    // Visual top edge of the card in panel coords. The Scale transform has its
    // origin at the card's top-left, so the scaled card's top stays at this y.
    // Computed explicitly (rather than read back from the anchor-resolved
    // card.y) so the cross-window stacking chain is robust to layout timing.
    readonly property real cardTopY:
        hud.anchorBelow ? (hud.anchorBelow.cardBottomY + hud.anchorGap)
                        : (hud.height * (0.5 + hud.vCenterOffsetRel)
                           - card.height * hud.uiScale / 2)

    // Exposed for siblings that want to stack against us. Bottom edge in screen
    // coords, accounting for the Scale transform applied to the card.
    readonly property real cardBottomY: cardTopY + card.height * uiScale

    // Where the bash script caches its JSON; same shape as the script's own
    // path so we can blow it away on SYNC.
    readonly property string cachePath:
        "/tmp/qs-issues-needs-reply-" + repo.replace(/\//g, "-") + ".json"

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
    WlrLayershell.namespace: "qs-issueshud-" + hud.stateKey

    // Track the *scaled* card bounds so clicks register on the visible area.
    mask: Region {
        x: card.x
        y: card.y
        width: card.width * hud.uiScale
        height: card.height * hud.uiScale
    }

    Poller {
        id: poll
        command: "~/.config/quickshell/scripts/issues-needs-reply.sh "
                 + JSON.stringify(hud.repo)
        interval: 60000
        running: watch.value
    }

    Process {
        id: refreshProc
        command: ["bash", "-c", 'rm -f "$1" 2>/dev/null', "_", hud.cachePath]
        running: false
        onExited: poll.refresh()
    }

    property var issues: {
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
            ? 50 + Math.max(1, hud.issues.length) * 24 + 14
            : 50
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Scale from the top-left; the PanelWindow's mask tracks the same.
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
                text: "● " + hud.issues.length
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
                visible: hud.issues.length === 0
                text: "   all caught up   "
                color: "#3a8a5a"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 4
            }

            Repeater {
                model: hud.issues
                delegate: PrItem {
                    prNum: modelData.number
                    title: modelData.title
                    url:   modelData.url
                    showCi: false
                    showLink: true
                    showTab: true
                    tabName: hud.tabName
                }
            }
        }
    }
}
