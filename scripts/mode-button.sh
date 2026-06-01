#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Activate a Hyprland mode end-to-end. The single entry point for both the
# eww WORK/HOME buttons (via launch.sh) and the `mode` CLI wrapper.
#
# For mode <work|home>:
#   1. Persist the mode for the eww highlight (state file + eww update for
#      instant feedback — the defpoll re-reads the file on its next tick).
#   2. Point the hypr/modes/current.conf symlink at the new mode.
#   3. Run display-setup.sh with the layout this mode uses. This applies
#      the new monitor layout via `hyprctl keyword monitor=…` AND writes
#      the new monitors-runtime.conf — both must happen before the reload
#      below, otherwise reload re-reads the OLD runtime conf and clobbers
#      the new layout (the "press twice" bug).
#   4. `hyprctl reload` so the new mode's windowrules/exec-onces apply and
#      the (already-correct) monitors-runtime.conf is re-confirmed.
#   5. Re-assert HUD visibility. Both `hyprctl keyword monitor=…` and
#      reload can drop layer-shell windows; re-opening is idempotent.
#   6. Launch any per-mode apps that aren't already running.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODES_DIR="$HOME/.config/hypr/modes"
STATE_FILE="$HOME/.local/state/eww-mode"
DISPLAY_SCRIPT="$SCRIPT_DIR/display-setup.sh"

case "${1:-}" in
    work) mode=work; layout=desk ;;
    home) mode=home; layout=home ;;
    *)    echo "Usage: $0 <work|home>" >&2; exit 1 ;;
esac

# 1. State for the eww WORK/HOME highlight. Push to the live var so the
#    highlight flips instantly instead of waiting on the 3s poll.
mkdir -p "$(dirname "$STATE_FILE")"
echo "$mode" > "$STATE_FILE"
eww update mode-state="$mode" >/dev/null 2>&1 || true

# 2. Switch the per-mode hypr config symlink. The reload that activates its
#    windowrules/exec-once happens in step 4, AFTER display-setup has
#    rewritten monitors-runtime.conf.
[[ -f "$MODES_DIR/$mode.conf" ]] || {
    echo "ERROR: $MODES_DIR/$mode.conf does not exist" >&2; exit 1; }
ln -sfn "$mode.conf" "$MODES_DIR/current.conf"

# 3. Monitor layout. Applies the new layout via `hyprctl keyword monitor=…`
#    and writes monitors-runtime.conf so the reload in step 4 picks up the
#    new layout (not the previous mode's, which used to cause the
#    "press twice" bug). Non-fatal: if the required external isn't
#    connected, log and continue — the rest of the mode switch is still
#    useful, and reload will just re-apply the previous runtime layout.
"$DISPLAY_SCRIPT" "$layout" || echo "display-setup.sh $layout failed (non-fatal)" >&2

# 4. Reload so the new mode's windowrules/exec-once apply. monitors-runtime.conf
#    is now correct, so reload won't clobber the layout from step 3.
hyprctl reload >/dev/null

# 5. HUDs. Always-on set re-asserted (workaround for layer drops on monitor
#    reconfig + reload). The tgt PR HUD now lives in quickshell and reacts to
#    mode-state.sh on its own, so there's nothing mode-specific to toggle here.
eww open-many stats-hud claude-hud top-hud >/dev/null 2>&1 || true
# launcher-hud has two variants (fg vs overlay layer) — pick by persisted state.
if [[ "$(cat ~/.local/state/eww-launcher-top 2>/dev/null)" == on ]]; then
    eww open launcher-hud-top >/dev/null 2>&1 || true
else
    eww open launcher-hud     >/dev/null 2>&1 || true
fi

# 6. Apps. launch_if_missing is idempotent — safe on every click.
has_class() {
    hyprctl clients -j 2>/dev/null \
        | jq -e --arg c "$1" 'any(.class == $c)' >/dev/null 2>&1
}
launch_if_missing() {
    local class=$1 cmd=$2
    if ! has_class "$class"; then
        # shellcheck disable=SC2086
        uwsm-app -- $cmd >/dev/null 2>&1 &
        disown
    fi
}

case "$mode" in
    work)
        launch_if_missing vivaldi-stable vivaldi
        launch_if_missing google-chrome   google-chrome-stable
        launch_if_missing Alacritty       alacritty
        ;;
    home)
        launch_if_missing vivaldi-stable vivaldi
        launch_if_missing google-chrome   google-chrome-stable
        ;;
esac

echo "Mode: $mode"
