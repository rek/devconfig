#!/usr/bin/env bash
# Set (or toggle) the pyprland dropdown terminal's force_monitor.
# Connector assignments drift (e.g. Acer sometimes lands on DP-1, sometimes DP-2),
# so an explicit pick is simpler than trying to match by monitor description —
# pyprland's force_monitor compares against connector names directly.
#
# Usage: ddterm-toggle-monitor.sh [DP-1|DP-2]
#   With no arg: flips between DP-1 and DP-2.
#   With arg:   sets to that connector (no-op if already set).

set -euo pipefail

CONFIG="$HOME/.config/pypr/config.toml"

current=$(grep -E '^force_monitor' "$CONFIG" | sed -E 's/.*"(.+)".*/\1/')

if [[ $# -ge 1 ]]; then
  new="$1"
else
  case "$current" in
    DP-1) new="DP-2" ;;
    *)    new="DP-1" ;;
  esac
fi

[[ "$new" == "$current" ]] && exit 0

sed -i -E "s/^force_monitor = \".*\"/force_monitor = \"$new\"/" "$CONFIG"
pypr reload

desc=$(hyprctl monitors -j | jq -r --arg n "$new" '.[] | select(.name==$n) | .description' | awk '{print $1, $2}')
notify-send "Dropdown terminal" "Now on $new${desc:+ ($desc)}" -t 1500
