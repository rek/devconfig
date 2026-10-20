#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Activate a Hyprland mode end-to-end. The single entry point for both the
# quickshell WORK/HOME buttons (via scripts/launch.sh) and the `mode` CLI
# wrapper.
#
# For mode <work|home>:
#   1. Persist the mode for the launcher highlight (state file, read by
#      scripts/mode-state.sh on the quickshell side).
#   2. `hyprctl reload` FIRST. Omarchy's Quatro release switched Hyprland to
#      native Lua config (hyprland.lua), which re-runs monitors.lua on every
#      reload — including its wildcard/auto fallback for any monitor not
#      explicitly named there. Reloading before display-setup.sh means that
#      fallback settles BEFORE we apply the real layout, instead of stomping
#      it after.
#   3. Run display-setup.sh with the layout this mode uses. Applies the new
#      monitor layout via `hyprctl eval 'hl.monitor({...})'` (the old
#      `hyprctl keyword monitor=…` no longer works under the Lua config
#      parser) and persists it to ~/.config/hypr/monitors-runtime.lua. This
#      runs LAST among config-affecting steps so nothing overwrites it after.
#   4. Launch any per-mode apps that aren't already running.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="$HOME/.local/state/mode"
DISPLAY_SCRIPT="$SCRIPT_DIR/display-setup.sh"

case "${1:-}" in
    work) mode=work; layout=desk ;;
    home) mode=home; layout=home ;;
    *)    echo "Usage: $0 <work|home>" >&2; exit 1 ;;
esac

# 1. State for the WORK/HOME highlight. mode-state.sh polls this file, so the
#    highlight flips on the next tick.
mkdir -p "$(dirname "$STATE_FILE")"
echo "$mode" > "$STATE_FILE"

# 2. Reload the base Lua config first, so its wildcard monitor fallback
#    settles before we apply the real layout in step 3 — not after.
hyprctl reload >/dev/null

# 3. Monitor layout. Applies the new layout via `hyprctl eval` and persists
#    it to monitors-runtime.lua. Runs LAST so nothing overwrites it.
#    Non-fatal: if the required external isn't connected, log and
#    continue — the rest of the mode switch is still useful.
"$DISPLAY_SCRIPT" "$layout" || echo "display-setup.sh $layout failed (non-fatal)" >&2

# 4. Apps. launch_if_missing is idempotent — safe on every click.
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
        launch_if_missing google-chrome   "$HOME/.local/bin/google-chrome-stable-igpu"
        launch_if_missing Alacritty       alacritty
        ;;
    home)
        launch_if_missing vivaldi-stable vivaldi
        launch_if_missing google-chrome   "$HOME/.local/bin/google-chrome-stable-igpu"
        ;;
esac

echo "Mode: $mode"
