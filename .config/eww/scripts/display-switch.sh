#!/usr/bin/env bash
# Wrapper for the eww GLASS/LAPTOP buttons. Runs display-setup.sh with the
# given layout, then `hyprctl reload` + re-opens eww HUDs.
#
# Why this exists: `hyprctl keyword monitor=...` (what display-setup.sh uses)
# applies layouts live but can leave the laptop panel with torn/split render
# state when an existing monitor is repositioned, and it can drop layer-shell
# surfaces anchored to eDP-2 (all our HUDs). mode-button.sh handles this the
# same way for WORK/HOME — the GLASS/LAPTOP buttons need the same treatment.

set -euo pipefail

case "${1:-}" in
    laptop|glasses-only) layout="$1" ;;
    *) echo "Usage: $0 <laptop|glasses-only>" >&2; exit 1 ;;
esac

"$HOME/dev/devconfig/scripts/display-setup.sh" "$layout"

hyprctl reload >/dev/null

# Re-open HUDs idempotently (no-op if still alive). Mirrors mode-button.sh.
eww open-many stats-hud claude-hud top-hud >/dev/null 2>&1 || true
if [[ "$(cat ~/.local/state/eww-launcher-top 2>/dev/null)" == on ]]; then
    eww open launcher-hud-top >/dev/null 2>&1 || true
else
    eww open launcher-hud     >/dev/null 2>&1 || true
fi
