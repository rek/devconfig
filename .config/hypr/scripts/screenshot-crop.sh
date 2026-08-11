#!/bin/bash
# GNOME-style screenshot: grab the focused monitor instantly, then open satty
# with the crop tool. The crop rectangle stays on screen and is fully
# adjustable (drag the handles) until you commit with Enter (or the toolbar
# save button) -- nothing is finalized on mouse release.
#
# No hyprpicker freeze and no `grim -c`, so the mouse pointer is never baked
# into the capture.

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
mkdir -p "$OUTPUT_DIR"

# Capture the currently focused monitor. grim omits the cursor by default.
FOCUSED=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name')
FILEPATH="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
grim -o "$FOCUSED" "$FILEPATH" || exit 1

# Open satty fullscreen on this screen with the crop tool active. Position and
# refine the crop, then press Enter to crop -> copy to clipboard -> save -> exit.
satty --filename "$FILEPATH" \
  --output-filename "$FILEPATH" \
  --fullscreen current-screen \
  --initial-tool crop \
  --actions-on-enter save-to-clipboard,save-to-file,exit \
  --save-after-copy \
  --copy-command 'wl-copy'
