#!/bin/bash
# Move the active window to the next monitor.
# Exits fullscreen first if needed, since Hyprland refuses to move fullscreen windows.

set -euo pipefail

fullscreen=$(hyprctl activewindow -j | jq -r '.fullscreen // 0')
if [[ "$fullscreen" != "0" && "$fullscreen" != "false" ]]; then
  hyprctl dispatch fullscreenstate 0 0
fi

hyprctl dispatch movewindow mon:+1
