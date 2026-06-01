#!/bin/bash
# Slurp region -> grim -> satty with crop tool active, so the screenshot
# isn't finalized until you confirm in satty (where you can refine the crop).

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}"
mkdir -p "$OUTPUT_DIR"

# Toggle: if a slurp is already open, kill it and bail.
pkill slurp && exit 0

# Freeze the screen so the selection sees a static image.
hyprpicker -r -z >/dev/null 2>&1 &
PICKER_PID=$!
trap '[[ -n $PICKER_PID ]] && kill $PICKER_PID 2>/dev/null' EXIT
sleep .1

SELECTION=$(slurp 2>/dev/null)
[[ -z $SELECTION ]] && exit 0

FILEPATH="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
grim -g "$SELECTION" "$FILEPATH" || exit 1

# Release the freeze before satty opens its own window.
kill $PICKER_PID 2>/dev/null
PICKER_PID=

satty --filename "$FILEPATH" \
  --output-filename "$FILEPATH" \
  --initial-tool crop \
  --early-exit \
  --actions-on-enter save-to-clipboard \
  --save-after-copy \
  --copy-command 'wl-copy'
