#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Activate a Hyprland mode end-to-end. The single entry point for both the
# eww WORK/HOME buttons (via launch.sh) and the `mode` CLI wrapper.
#
# For mode <work|home>:
#   1. Persist the mode for the eww highlight (state file + eww update for
#      instant feedback — the defpoll re-reads the file on its next tick).
#   2. Point the hypr/modes/current.conf symlink at the new mode (legacy;
#      nothing sources this chain since Omarchy's Lua config migration —
#      see the note below step 4).
#   3. `hyprctl reload` FIRST. Omarchy's Quatro release switched Hyprland to
#      native Lua config (hyprland.lua), which re-runs monitors.lua on every
#      reload — including its wildcard/auto fallback for any monitor not
#      explicitly named there. Reloading before display-setup.sh means that
#      fallback settles BEFORE we apply the real layout, instead of stomping
#      it after (this order was the opposite under the old .conf chain,
#      where reload used to re-source monitors-runtime.conf — that source
#      line no longer does anything under hyprland.lua).
#   4. Run display-setup.sh with the layout this mode uses. Applies the new
#      monitor layout via `hyprctl eval 'hl.monitor({...})'` (the old
#      `hyprctl keyword monitor=…` no longer works under the Lua config
#      parser) and writes monitors-runtime.conf for reference. This runs
#      LAST among config-affecting steps so nothing overwrites it after.
#   5. Re-assert HUD visibility. Both the eval calls above and the reload
#      can drop layer-shell windows; re-opening is idempotent.
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

# 2. Switch the per-mode hypr config symlink (legacy — see step-list note above).
[[ -f "$MODES_DIR/$mode.conf" ]] || {
    echo "ERROR: $MODES_DIR/$mode.conf does not exist" >&2; exit 1; }
ln -sfn "$mode.conf" "$MODES_DIR/current.conf"

# 3. Reload the base Lua config first, so its wildcard monitor fallback
#    settles before we apply the real layout in step 4 — not after.
hyprctl reload >/dev/null

# 4. Monitor layout. Applies the new layout via `hyprctl eval` and writes
#    monitors-runtime.conf for reference. Runs LAST so nothing overwrites
#    it. Non-fatal: if the required external isn't connected, log and
#    continue — the rest of the mode switch is still useful.
"$DISPLAY_SCRIPT" "$layout" || echo "display-setup.sh $layout failed (non-fatal)" >&2

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
