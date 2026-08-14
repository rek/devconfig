// Periodically runs a shell command and exposes its stdout via `value`.
// Quickshell equivalent of an eww `defpoll`.
//
//     Poller { id: cpu; command: "~/.config/eww/scripts/cpu.sh"; interval: 2000 }
//     ...
//     Text { text: cpu.value }                  // raw string
//     Text { text: (parseFloat(cpu.value) || 0).toFixed(0) + "%" }

import QtQuick
import Quickshell.Io

Item {
    id: root

    // Shell command run via `bash -c`. Deliberately NOT a login shell: `-l`
    // sources /etc/profile.d/, and vapoursynth.sh there spawns a Python
    // interpreter per poll — ~2/s of pure CPU churn for an unused env var.
    property string command: ""

    // Poll interval in ms.
    property int interval: 2000

    // Latest stdout (trimmed). Empty until first run completes.
    property string value: ""

    // Set false to pause polling (e.g. when a HUD is collapsed/hidden).
    property bool running: true

    // Force an immediate poll, ignoring the timer cycle.
    function refresh() { proc.running = true }

    Timer {
        interval: root.interval
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", root.command]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.value = text.trim()
        }
    }
}
