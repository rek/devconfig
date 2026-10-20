#!/usr/bin/env bash
# Wrapper for the GLASS/LAPTOP launcher buttons. Runs display-setup.sh with the
# given layout, then `hyprctl reload`.
#
# Why this exists: applying a layout live can leave the laptop panel with
# torn/split render state when an existing monitor is repositioned, and it can
# drop layer-shell surfaces anchored to eDP-2 (all our HUDs). mode-button.sh
# handles this the same way for WORK/HOME — the GLASS/LAPTOP buttons need the
# same treatment.
#
# The HUDs live in quickshell now, and quickshell re-asserts its own layers,
# so there is nothing to re-open here.

set -euo pipefail

case "${1:-}" in
    laptop|glasses-only) layout="$1" ;;
    *) echo "Usage: $0 <laptop|glasses-only>" >&2; exit 1 ;;
esac

"$HOME/dev/devconfig/scripts/display-setup.sh" "$layout"

hyprctl reload >/dev/null
