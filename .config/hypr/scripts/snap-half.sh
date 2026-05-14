#!/bin/bash
# Snap the active window to the left or right half of its current monitor.
# Float and exit fullscreen first if needed. Other tiled windows on the
# monitor retile naturally to fill the freed space.
#
# Usage: snap-half.sh left|right

set -euo pipefail

side="${1:-}"
case "$side" in
  left|right) ;;
  *) echo "usage: $0 left|right" >&2; exit 2 ;;
esac

win=$(hyprctl activewindow -j)
fullscreen=$(jq -r '.fullscreen // 0' <<<"$win")
floating=$(jq -r '.floating' <<<"$win")
mon_id=$(jq -r '.monitor' <<<"$win")

mon=$(hyprctl monitors -j | jq ".[] | select(.id == $mon_id)")
mx=$(jq -r '.x' <<<"$mon")
my=$(jq -r '.y' <<<"$mon")
mw=$(jq -r '.width' <<<"$mon")
mh=$(jq -r '.height' <<<"$mon")
scale=$(jq -r '.scale' <<<"$mon")
res_top=$(jq -r '.reserved[1]' <<<"$mon")
res_bot=$(jq -r '.reserved[3]' <<<"$mon")

# Effective workspace size in logical pixels, accounting for scale and reserved bars.
logical_w=$(awk -v w="$mw" -v s="$scale" 'BEGIN { printf "%d", w / s }')
logical_h=$(awk -v h="$mh" -v s="$scale" -v t="$res_top" -v b="$res_bot" \
  'BEGIN { printf "%d", (h / s) - t - b }')
half_w=$(( logical_w / 2 ))
y_top=$(( my + res_top ))

if [[ "$side" == "left" ]]; then
  target_x=$mx
else
  target_x=$(( mx + half_w ))
fi

if [[ "$fullscreen" != "0" && "$fullscreen" != "false" ]]; then
  hyprctl dispatch fullscreenstate 0 0
fi
if [[ "$floating" == "false" ]]; then
  hyprctl dispatch togglefloating
fi

hyprctl dispatch resizeactive exact "$half_w" "$logical_h"
hyprctl dispatch moveactive exact "$target_x" "$y_top"
