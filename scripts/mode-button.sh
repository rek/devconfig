#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Activate a Hyprland mode end-to-end. The single entry point for both the
# eww WORK/HOME buttons (via launch.sh) and the `mode` CLI wrapper.
#
# For mode <work|home>:
#   1. Persist the mode for the eww highlight (state file + eww update for
#      instant feedback — the defpoll re-reads the file on its next tick).
#   2. Activate the matching hypr/modes/<mode>.conf via the current.conf
#      symlink, then `hyprctl reload` so its windowrules/exec-onces apply.
#   3. Run display-setup.sh with the layout this mode uses.
#   4. Re-assert HUD visibility. `hyprctl keyword monitor=…` can drop
#      layer-shell windows on the reconfigured output; re-opening is
#      idempotent. pr-hud is work-only.
#   5. Launch any per-mode apps that aren't already running.
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

# Order matters: do the cheap/always-works steps first (state, hypr config,
# HUDs) so a hardware-dependent display-setup failure (e.g. external not
# connected) still leaves the user with the right mode + HUDs + windowrules.

# 1. State for the eww WORK/HOME highlight. Push to the live var so the
#    highlight flips instantly instead of waiting on the 3s poll.
mkdir -p "$(dirname "$STATE_FILE")"
echo "$mode" > "$STATE_FILE"
eww update mode-state="$mode" >/dev/null 2>&1 || true

# 2. Switch the per-mode hypr config (windowrules + exec-once). Without this,
#    work.conf's `workspace 2 silent, match:class ^Alacritty$` never applies.
[[ -f "$MODES_DIR/$mode.conf" ]] || {
    echo "ERROR: $MODES_DIR/$mode.conf does not exist" >&2; exit 1; }
ln -sfn "$mode.conf" "$MODES_DIR/current.conf"
hyprctl reload >/dev/null

# 3. HUDs. Always-on set re-asserted (workaround for layer drops on monitor
#    reconfig); pr-hud follows mode.
eww open-many stats-hud claude-hud top-hud >/dev/null 2>&1 || true
# launcher-hud has two variants (fg vs overlay layer) — pick by persisted state.
if [[ "$(cat ~/.local/state/eww-launcher-top 2>/dev/null)" == on ]]; then
    eww open launcher-hud-top >/dev/null 2>&1 || true
else
    eww open launcher-hud     >/dev/null 2>&1 || true
fi
case "$mode" in
    work)
        # pr-hud has two variants (fg vs overlay layer) — pick by persisted state.
        if [[ "$(cat ~/.local/state/eww-pr-top 2>/dev/null)" == on ]]; then
            eww open pr-hud-top >/dev/null 2>&1 || true
        else
            eww open pr-hud     >/dev/null 2>&1 || true
        fi
        ;;
    home)
        eww close pr-hud     >/dev/null 2>&1 || true
        eww close pr-hud-top >/dev/null 2>&1 || true
        ;;
esac

# 4. Monitor layout. Layouts persist via ~/.config/hypr/monitors-runtime.conf.
#    Non-fatal: if the required external isn't connected, log and continue —
#    the rest of the mode switch is still useful.
"$DISPLAY_SCRIPT" "$layout" || echo "display-setup.sh $layout failed (non-fatal)" >&2

# 5. Apps. launch_if_missing is idempotent — safe on every click.
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
