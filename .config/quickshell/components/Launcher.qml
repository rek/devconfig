// Synthwave launcher — two rows of LaunchButtons centered on eDP-2. Flat port
// of the eww `launcher` widget (eww.yuck). Composes the reusable primitives:
// Theme (palette), LaunchButton (button), Poller (state), ToggleButton (pin).
//
// The always-on-top pin toggles the WHOLE window between the Bottom layer
// (tucked behind windows) and Overlay (above fullscreen) — one window bound to
// a toggle, replacing eww's two-sibling-window (launcher-hud/-top) hack.
//
// Flat (no glow) for now — the eww launcher it replaces had a neon bloom that
// can be layered back on later via Glow/MultiEffect (the icon/label Items are
// structured as glow sources). Sits bottom-center of eDP-2.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: hud

    screen: {
        for (let s of Quickshell.screens) {
            if (s.name === "eDP-2") return s;
        }
        return Quickshell.screens[0];
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: pin.value ? WlrLayer.Overlay : WlrLayer.Bottom
    WlrLayershell.namespace: "qs-launcher"

    // Click-through everywhere except the panel itself.
    mask: Region {
        x: panel.x; y: panel.y; width: panel.width; height: panel.height
    }

    // State pollers — the same scripts the eww launcher used.
    Poller { id: modeState;   command: "~/.config/eww/scripts/mode-state.sh";       interval: 3000 }
    Poller { id: nightState;  command: "~/.config/eww/scripts/nightlight-state.sh"; interval: 3000 }
    Poller { id: phoneState;  command: "~/.config/quickshell/scripts/headphone-state.sh";  interval: 3000 }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24   // matches the eww launcher's bottom-center inset

        width:  content.implicitWidth + 32
        height: content.implicitHeight + 22
        radius: 12
        color: Theme.panel
        border.color: Theme.magenta
        border.width: 2

        // Cyan top/bottom edge strips — QML borders are single-color, so the
        // magenta border rings the panel and these supply eww's cyan top/bottom
        // accent. Inset by the corner radius to clear the rounded corners.
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right
                      leftMargin: parent.radius; rightMargin: parent.radius }
            height: 2; color: Theme.cyan
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right
                      leftMargin: parent.radius; rightMargin: parent.radius }
            height: 2; color: Theme.cyan
        }

        Column {
            id: content
            anchors.centerIn: parent
            spacing: 10

            // Row 1 — mode + display. WORK/HOME highlight when active.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                LaunchButton { icon: "";   label: "WORK";   active: modeState.value === "work";
                    command: "~/.config/eww/scripts/launch.sh ~/dev/devconfig/scripts/mode-button.sh work" }
                LaunchButton { icon: "";   label: "HOME";   active: modeState.value === "home";
                    command: "~/.config/eww/scripts/launch.sh ~/dev/devconfig/scripts/mode-button.sh home" }
                LaunchButton { icon: "󰓹";  label: "GLASS";
                    command: "~/.config/eww/scripts/launch.sh ~/.config/eww/scripts/display-switch.sh glasses-only" }
                LaunchButton { icon: "󰌢"; label: "LAPTOP";
                    command: "~/.config/eww/scripts/launch.sh ~/.config/eww/scripts/display-switch.sh laptop" }
                LaunchButton { icon: "󰋋"; label: "PHONES"; active: phoneState.value === "on";
                    command: "~/.config/eww/scripts/launch.sh ~/.config/quickshell/scripts/headphone-toggle.sh" }
            }

            // Row 2 — actions. NIGHT highlights when nightlight is on.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                LaunchButton { icon: ""; label: "FILES";
                    command: "~/.config/eww/scripts/launch.sh uwsm-app -- nautilus --new-window" }
                LaunchButton { icon: "";  label: "LOCK";
                    command: "~/.config/eww/scripts/launch.sh omarchy system lock" }
                LaunchButton { icon: "";  label: "SHOT";
                    command: "~/.config/eww/scripts/launch.sh omarchy capture screenshot" }
                LaunchButton { icon: ""; label: "SLEEP";
                    command: "~/.config/eww/scripts/launch.sh systemctl suspend" }
                LaunchButton { icon: ""; label: "BLANK";
                    command: "~/.config/eww/scripts/launch.sh ~/.config/eww/scripts/display-off.sh" }
                LaunchButton { icon: ""; label: "NIGHT"; active: nightState.value === "on";
                    command: "~/.config/eww/scripts/launch.sh omarchy toggle nightlight" }
                LaunchButton { icon: ""; label: "THEME";
                    command: "~/.config/eww/scripts/launch.sh omarchy theme bg next" }
            }
        }

        // Always-on-top pin, top-right corner — reuses the persisted toggle.
        ToggleButton {
            id: pin
            stateName: "launcher-top"
            iconOn:  ""
            iconOff: ""
            accent: Theme.magenta
            dim:    Theme.textDim
            fillOn: Theme.activeFill
            anchors { top: parent.top; right: parent.right; topMargin: 8; rightMargin: 8 }
        }
    }
}
