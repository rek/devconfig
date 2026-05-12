#!/bin/bash
# Re-integrate the active window into the tile grid on its current monitor:
# - exit fullscreen if it's fullscreen
# - toggle to tiled if it's floating

set -euo pipefail

win=$(hyprctl activewindow -j)
fullscreen=$(jq -r '.fullscreen // 0' <<<"$win")
floating=$(jq -r '.floating' <<<"$win")

if [[ "$fullscreen" != "0" && "$fullscreen" != "false" ]]; then
  hyprctl dispatch fullscreenstate 0 0
fi

if [[ "$floating" == "true" ]]; then
  hyprctl dispatch togglefloating
fi
