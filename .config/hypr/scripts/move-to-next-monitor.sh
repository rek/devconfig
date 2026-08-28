#!/bin/bash
# Move the active window to the next monitor.
# Exits fullscreen first if needed, since Hyprland refuses to move fullscreen windows.
#
# Uses `hyprctl eval` + hl.dsp.*, not `hyprctl dispatch <name> <args>`: Omarchy's
# Quatro release switched Hyprland to native Lua config, and `hyprctl dispatch`
# now tries to parse its argument as a Lua expression instead of the old
# space-separated dispatcher syntax, so the legacy form silently errors.

set -euo pipefail

fullscreen=$(hyprctl activewindow -j | jq -r '.fullscreen // 0')
if [[ "$fullscreen" != "0" && "$fullscreen" != "false" ]]; then
  hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))' >/dev/null
fi

hyprctl eval 'hl.dispatch(hl.dsp.window.move({ monitor = "+1" }))' >/dev/null
