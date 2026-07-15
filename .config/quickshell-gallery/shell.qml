// Keyboard-HUD design gallery — 24 live redesigns of KeyboardHud.qml tiled
// across eDP-2, all fed by the same real keyboard-state.sh poll so you can
// judge them against actual link/battery state, not mockups.
//
// Standalone quickshell instance — does NOT touch the real ~/.config/quickshell
// shell.qml. Launch:  quickshell -c ~/dev/devconfig/.config/quickshell-gallery
// Close:              pkill -f 'quickshell -c.*quickshell-gallery'

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"

ShellRoot {
    id: root

    Poller {
        id: kb
        command: "~/.config/quickshell/scripts/keyboard-state.sh"
        interval: 15000
    }

    readonly property var parts: (kb.value || "off|--|--").split("|")
    readonly property string link: parts[0] || "off"
    readonly property string lpct: parts[1] || "--"
    readonly property string rpct: parts[2] || "--"
    readonly property color accent: link === "usb" ? "#ffb000" : link === "ble" ? "#00fff9" : "#446655"

    readonly property var variants: [
        { c: "V01_KeycapCell",       n: "01 · Keycap Silhouette" },
        { c: "V02_PcbTraceCell",     n: "02 · PCB Trace Map" },
        { c: "V03_RadarSweepCell",   n: "03 · Radar Sweep" },
        { c: "V04_LcdDigitCell",     n: "04 · LCD Digit" },
        { c: "V05_VuMeterCell",      n: "05 · VU Meter" },
        { c: "V06_OscilloscopeCell", n: "06 · Oscilloscope" },
        { c: "V07_HoloHexCell",      n: "07 · Holographic Hex" },
        { c: "V08_GlassCell",        n: "08 · Minimalist Glass" },
        { c: "V09_AsciiTerminalCell",n: "09 · Brutalist ASCII" },
        { c: "V10_OutrunHorizonCell",n: "10 · Outrun Horizon" },
        { c: "V11_SonarPingCell",    n: "11 · Sonar Ping" },
        { c: "V12_BlueprintCell",    n: "12 · Blueprint" },
        { c: "V13_BatteryCellCell",  n: "13 · Battery Skeuomorph" },
        { c: "V14_SignalBarsCell",   n: "14 · Signal Bars + Glow" },
        { c: "V15_FlipDiagnosticCell", n: "15 · Flip Diagnostic" },
        { c: "V16_EmberParticleCell",n: "16 · Ember Particles" },
        { c: "V17_BootLogCell",      n: "17 · Boot Log" },
        { c: "V18_LedBargraphCell",  n: "18 · LED Bargraph" },
        { c: "V19_DotMatrixCell",    n: "19 · Dot Matrix" },
        { c: "V20_CassetteCell",     n: "20 · Cassette Tape" },
        { c: "V21_OrigamiCell",      n: "21 · Origami Fold" },
        { c: "V22_VinylCell",        n: "22 · Vinyl Record" },
        { c: "V23_BinaryPulseCell",  n: "23 · Binary Pulse" },
        { c: "V24_AuroraCell",       n: "24 · Aurora Wave" },
    ]

    PanelWindow {
        id: gallery
        screen: {
            for (let s of Quickshell.screens) {
                if (s.name === "eDP-2") return s;
            }
            return Quickshell.screens[0];
        }
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "#0b0b0d"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qs-keyboard-hud-gallery"

        Text {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 10
            text: "keyboard HUD — design gallery  ·  link " + root.link + "  L " + root.lpct + "%  R " + root.rpct + "%  ·  pick your favorites"
            color: "#666"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }

        Grid {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 14
            columns: 6
            rowSpacing: 24
            columnSpacing: 14

            Repeater {
                model: root.variants
                delegate: Column {
                    spacing: 6
                    Rectangle {
                        width: 400; height: 330
                        radius: 10
                        color: "#141416"
                        border.color: "#25252a"
                        border.width: 1
                        clip: true

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: Qt.resolvedUrl("components/" + modelData.c + ".qml")
                            onLoaded: {
                                item.link = root.link;
                                item.lpct = root.lpct;
                                item.rpct = root.rpct;
                                item.accent = root.accent;
                            }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.n
                        color: "#8a8a8a"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
