// Synthwave/outrun palette — the "new theme" for the launcher (and any future
// magenta/cyan components), ported from the eww launcher's eww.scss. Kept in
// its own dir with a qmldir so it's a real singleton without disturbing the
// auto-discovered components/ directory.
//
//     import "../theme"
//     ...
//     color: Theme.cyan
//
// The existing green HUDs (#00ff88) are unaffected — they keep their own
// hardcoded colors.

pragma Singleton
import QtQuick

QtObject {
    readonly property color magenta:    "#ff2bd6"
    readonly property color magentaDim: Qt.rgba(1, 0.169, 0.839, 0.28)
    readonly property color cyan:       "#00fff9"
    readonly property color cyanDim:    Qt.rgba(0, 1, 0.976, 0.22)
    readonly property color text:       "#f6e9ff"
    readonly property color textDim:    "#b58fcf"
    // ~72% alpha over near-black, like eww's $panel (the clickable launcher).
    readonly property color panel:      Qt.rgba(8/255, 4/255, 22/255, 0.72)
    readonly property color hoverFill:  Qt.rgba(1, 0.169, 0.839, 0.18)  // magenta-tint hover bg
    readonly property color activeFill: Qt.rgba(0, 1, 0.976, 0.15)      // cyan-tint toggled-on bg

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
