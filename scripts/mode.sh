#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Mode switcher: work / home
#
# Combines monitor layout (display-setup.sh) with Hyprland app placement +
# auto-launch. The active mode is selected via a symlink in
# ~/.config/hypr/modes/current.conf which hyprland.conf sources.
#
#   mode work     desk display + Vivaldi/Chrome on WS3, Alacritty on WS2
#   mode home     home display + Vivaldi/Chrome (placement TBD)
#   mode status   show current mode + monitor layout
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISPLAY_SCRIPT="$SCRIPT_DIR/display-setup.sh"
MODES_DIR="$HOME/.config/hypr/modes"

require() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 not found" >&2; exit 1; }
}

set_active() {
    local name=$1
    [[ -f "$MODES_DIR/$name.conf" ]] || {
        echo "ERROR: $MODES_DIR/$name.conf does not exist" >&2; exit 1; }
    ln -sfn "$name.conf" "$MODES_DIR/current.conf"
}

# Returns 0 if any running Hyprland client has the given window class.
has_class() {
    hyprctl clients -j 2>/dev/null \
        | jq -e --arg c "$1" 'any(.class == $c)' >/dev/null 2>&1
}

# Launch via uwsm-app if no window of the given class is currently mapped.
launch_if_missing() {
    local class=$1 cmd=$2
    if has_class "$class"; then
        echo "  already running: $class"
    else
        echo "  launching: $cmd"
        # shellcheck disable=SC2086
        uwsm-app -- $cmd >/dev/null 2>&1 &
        disown
    fi
}

mode_work() {
    "$DISPLAY_SCRIPT" desk
    set_active work
    hyprctl reload >/dev/null
    eww open pr-hud >/dev/null 2>&1 || true   # work-only HUD
    echo
    echo "Work apps:"
    launch_if_missing vivaldi-stable vivaldi
    launch_if_missing google-chrome   google-chrome-stable
    launch_if_missing Alacritty       alacritty
    echo
    echo "Mode: work"
}

mode_home() {
    "$DISPLAY_SCRIPT" home
    set_active home
    hyprctl reload >/dev/null
    eww close pr-hud >/dev/null 2>&1 || true   # work-only HUD
    echo
    echo "Home apps:"
    launch_if_missing vivaldi-stable vivaldi
    launch_if_missing google-chrome   google-chrome-stable
    echo
    echo "Mode: home"
}

mode_status() {
    if [[ -L "$MODES_DIR/current.conf" ]]; then
        local target
        target=$(readlink "$MODES_DIR/current.conf")
        echo "Mode: ${target%.conf}"
    else
        echo "Mode: (none — $MODES_DIR/current.conf is not a symlink)"
    fi
    echo
    hyprctl monitors | grep -E "^Monitor|description" | head -20
}

usage() {
    cat <<EOF
Usage: mode <work|home|status>

  work     desk display layout + Vivaldi/Chrome on WS3, Alacritty on WS2
  home     home display layout + Vivaldi/Chrome (placement TBD)
  status   show current mode + monitor layout
EOF
}

main() {
    require hyprctl
    require jq
    require uwsm-app
    case "${1:-}" in
        work)          mode_work ;;
        home)          mode_home ;;
        status)        mode_status ;;
        ""|-h|--help)  usage ;;
        *)             usage; exit 1 ;;
    esac
}

main "$@"
