#!/bin/bash
# Focus, or move the active window to, the next/previous REAL monitor.
#
#   cycle-monitor.sh focus next|prev
#   cycle-monitor.sh move  next|prev
#
# Why not Hyprland's built-in `monitor = "+1"`: the headless CAPTURE output
# (Godot test runs, see windowrules.lua) counts as a monitor and sits between
# the laptop panel and the external one in id order, so "+1" sent windows and
# focus off to an invisible screen. This walks the enabled monitors in id
# order and skips CAPTURE.
#
# Uses `hyprctl eval` + hl.dsp.*: under the Lua config, `hyprctl dispatch`
# parses its argument as Lua, so the legacy dispatcher syntax silently errors.

set -euo pipefail

action=${1:?usage: cycle-monitor.sh focus|move next|prev}
direction=${2:-next}
hidden='^CAPTURE$'

mapfile -t monitors < <(hyprctl monitors -j |
  jq -r --arg hidden "$hidden" \
    '[.[] | select(.disabled | not) | select(.name | test($hidden) | not)] | sort_by(.id) | .[].name')
current=$(hyprctl activeworkspace -j | jq -r '.monitor')

count=${#monitors[@]}
((count > 0)) || exit 0

# Index of the current monitor; -1 if focus is on CAPTURE itself, which makes
# "next" land on the first real monitor (a way back out).
index=-1
for i in "${!monitors[@]}"; do
  [[ ${monitors[$i]} == "$current" ]] && index=$i
done

if [[ $direction == prev ]]; then
  ((index < 0)) && index=0
  target=${monitors[$(((index - 1 + count) % count))]}
else
  target=${monitors[$(((index + 1) % count))]}
fi

case $action in
focus)
  hyprctl eval "hl.dispatch(hl.dsp.focus({ monitor = \"$target\" }))" >/dev/null
  ;;
move)
  # Hyprland refuses to move fullscreen windows, so drop fullscreen first.
  fullscreen=$(hyprctl activewindow -j | jq -r '.fullscreen // 0')
  if [[ $fullscreen != "0" && $fullscreen != "false" ]]; then
    hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))' >/dev/null
  fi
  hyprctl eval "hl.dispatch(hl.dsp.window.move({ monitor = \"$target\" }))" >/dev/null
  ;;
*)
  echo "unknown action: $action" >&2
  exit 1
  ;;
esac
