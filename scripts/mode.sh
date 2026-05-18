#!/usr/bin/env bash
# Thin CLI wrapper around mode-button.sh — the actual switch logic lives there
# and is shared with the eww WORK/HOME buttons. This script exists so `mode`
# from a terminal stays a one-liner and so `mode status` has a home.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODES_DIR="$HOME/.config/hypr/modes"

usage() {
    cat <<EOF
Usage: mode <work|home|status>

  work     desk display layout + per-mode hypr config + work apps
  home     home display layout + per-mode hypr config + home apps
  status   show current mode + monitor layout
EOF
}

case "${1:-}" in
    work|home)
        exec "$SCRIPT_DIR/mode-button.sh" "$1"
        ;;
    status)
        if [[ -L "$MODES_DIR/current.conf" ]]; then
            target=$(readlink "$MODES_DIR/current.conf")
            echo "Mode: ${target%.conf}"
        else
            echo "Mode: (none — $MODES_DIR/current.conf is not a symlink)"
        fi
        echo
        hyprctl monitors | grep -E "^Monitor|description" | head -20
        ;;
    ""|-h|--help)
        usage
        ;;
    *)
        usage; exit 1
        ;;
esac
