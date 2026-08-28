#!/bin/bash
# Re-integrate the active window into the tile grid on its current monitor:
# - exit fullscreen if it's fullscreen
# - toggle to tiled if it's floating
#
# Uses `hyprctl eval` + hl.dsp.*, not `hyprctl dispatch <name> <args>`: Omarchy's
# Quatro release switched Hyprland to native Lua config, and `hyprctl dispatch`
# now tries to parse its argument as a Lua expression instead of the old
# space-separated dispatcher syntax, so the legacy form silently errors.

set -euo pipefail

win=$(hyprctl activewindow -j)
fullscreen=$(jq -r '.fullscreen // 0' <<<"$win")
floating=$(jq -r '.floating' <<<"$win")

if [[ "$fullscreen" != "0" && "$fullscreen" != "false" ]]; then
  hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))' >/dev/null
fi

if [[ "$floating" == "true" ]]; then
  hyprctl eval 'hl.dispatch(hl.dsp.window.float({ action = "toggle" }))' >/dev/null
fi
