#!/usr/bin/env bash
# Rescue Steam windows that have drifted off-screen onto the glasses (XREAL).
#
# Steam on Wayland remembers stale absolute coordinates and frequently parks
# its windows outside any monitor's visible bounds — they look "minimized" or
# lost. This pulls every steam-class window onto the XREAL glasses' active
# workspace, clamps it back inside the visible area (cascaded so multiples
# don't fully overlap), and raises it to the top.
#
# Target monitor is matched by description (XREAL/Nreal) so it survives
# connector renames (DP-1 vs DP-2 drift); falls back to the focused monitor.
#
# Usage: restore-steam-windows.sh        (no args)

set -euo pipefail

mons=$(hyprctl monitors -j)

# Pick the glasses by description; fall back to whatever monitor is focused.
target=$(echo "$mons" | jq -r '
  ([.[] | select(.description | test("XREAL|Nreal"; "i"))] | first)
  // (.[] | select(.focused))
  | .name')

read -r mx my mw mh ws < <(echo "$mons" | jq -r --arg n "$target" '
  .[] | select(.name == $n)
  | "\(.x) \(.y) \(.width) \(.height) \(.activeWorkspace.id)"')

margin=40
step=48
i=0

# address size_w size_h, one steam window per line
steam=$(hyprctl clients -j | jq -r '
  .[] | select((.class // "" | ascii_downcase) == "steam")
  | "\(.address) \(.size[0]) \(.size[1])"')

if [[ -z "$steam" ]]; then
  notify-send "Steam" "No Steam windows found." -t 1500
  exit 0
fi

first=""
while read -r addr w h; do
  [[ -z "$addr" ]] && continue
  [[ -z "$first" ]] && first="$addr"

  # Cascade start position, then clamp so the window is fully on-screen.
  # Bounds are flush to the monitor edges (no margin) so a window nearly as
  # tall/wide as the screen still fits; the margin/cascade is best-effort.
  x=$(( mx + margin + i * step ))
  y=$(( my + margin + i * step ))
  maxx=$(( mx + mw - w ))
  maxy=$(( my + mh - h ))
  (( x > maxx )) && x=$maxx
  (( y > maxy )) && y=$maxy
  (( x < mx )) && x=$mx        # window wider than monitor: flush left
  (( y < my )) && y=$my        # window taller than monitor: flush top

  hyprctl dispatch movetoworkspacesilent "$ws,address:$addr" >/dev/null
  hyprctl dispatch movewindowpixel "exact $x $y,address:$addr" >/dev/null
  hyprctl dispatch alterzorder "top,address:$addr" >/dev/null
  i=$(( i + 1 ))
done <<< "$steam"

# Surface the workspace and land focus on the main window.
hyprctl dispatch workspace "$ws" >/dev/null
[[ -n "$first" ]] && hyprctl dispatch focuswindow "address:$first" >/dev/null

notify-send "Steam" "Restored $i window(s) to $target" -t 1500
