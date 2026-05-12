#!/bin/bash
# Resize active window to 100% width × 50% height.
# If the window is tiled, float it first so the exact resize sticks.

set -euo pipefail

echo "[$(date '+%F %T')] resize-half-height fired" >> /tmp/resize-half-height.log

floating=$(hyprctl activewindow -j | jq -r .floating)
[[ "$floating" == "false" ]] && hyprctl dispatch togglefloating
hyprctl dispatch resizeactive exact 100% 50%
