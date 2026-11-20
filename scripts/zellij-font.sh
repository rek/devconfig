#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Font size of Zellij terminal windows (`zellij terminal`, class
# dev.zellij.Zellij) per mode: work keeps the configured size (font_size 9 in
# config.kdl), home is two zoom steps larger.
#
# Zellij's terminal reads font_size only when a window opens, so instead of
# rewriting config.kdl (a tracked file) this zooms windows with the terminal's
# own keys: Ctrl+0 resets to the configured size, Ctrl+KP_Add is one step
# (1pt) larger. The keypad keys are used because `send_shortcut` with "minus"
# or "equal" does not reach Zellij.
#
# Usage:
#   zellij-font.sh             apply the current mode to every Zellij window
#   zellij-font.sh <address>   apply it to one window (Hyprland window.open
#                              hook in .config/hypr/windowrules.lua)
#
# Called by mode-button.sh after a mode switch. Best-effort: exits 0.
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

STATE_FILE="$HOME/.local/state/mode"
HOME_STEPS=2

mode=$(cat "$STATE_FILE" 2>/dev/null || echo none)
steps=0
[[ $mode == home ]] && steps=$HOME_STEPS

if [[ $# -gt 0 ]]; then
    addresses=("$1")
    # A new window: give Zellij a moment to map and draw before it gets keys.
    # It opens at the configured size, so in work mode there is nothing to do.
    [[ $steps -eq 0 ]] && exit 0
    sleep 0.6
else
    mapfile -t addresses < <(hyprctl clients -j 2>/dev/null \
        | jq -r '.[] | select(.class == "dev.zellij.Zellij") | .address')
fi

key() {
    hyprctl eval "hl.dispatch(hl.dsp.send_shortcut({ mods = 'CTRL', key = '$2', window = 'address:$1' }))" \
        >/dev/null 2>&1
    sleep 0.15
}

for addr in "${addresses[@]}"; do
    [[ $addr =~ ^0x[0-9a-f]+$ ]] || continue
    key "$addr" 0
    for ((i = 0; i < steps; i++)); do
        key "$addr" KP_Add
    done
done

exit 0
