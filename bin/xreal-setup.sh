#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# XReal Pro display setup for Omarchy / Arch (Hyprland / Wayland)
# ─────────────────────────────────────────────────────────────────────────────
#
# Auto-detects monitors via `hyprctl -j monitors all`:
#
#   Laptop  — connector name starts with eDP
#   Philips — description matches "Philips" / "PHL" (fallback: any 2560x1440)
#   Glasses — description matches "XREAL" / "Nreal"
#   Other   — anything else; fills the "third" slot in desk mode
#
# Modes:
#
#   extend          Philips (portrait) + Laptop + Glasses (glasses right of Philips)
#   desk            Philips (portrait) + Laptop (+ 2nd external if connected)
#   glasses-only    Glasses (top) + Laptop (bottom)
#   status          Print `hyprctl monitors` for the current layout
#
# Layouts are applied at runtime with `hyprctl keyword monitor=...` — they
# survive until the next Hyprland reload. Re-run this script after reload
# (or whenever you plug/unplug hardware).
#
# ─── History: this used to drive GNOME/Mutter on Ubuntu Wayland ──────────────
# Earlier versions called org.gnome.Mutter.DisplayConfig over D-Bus and could
# optionally hand control to breezy-desktop (the GNOME extension that turns
# the XReal glasses into a wide virtual canvas). Neither has a Hyprland
# equivalent today, so `triple` mode and `install-breezy` are gone — the
# glasses act as a plain 1920x1080 DP monitor on Hyprland.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Hardware-specific modes. The Philips 278B1 advertises 3840x2160@30 as its
# EDID-preferred mode (it's a 1440p panel that accepts a downscaled 4K
# signal), so we can't trust `preferred` for it. The XReal glasses always
# enumerate as 1920x1080. Laptop stays on `preferred` so this script works
# on whatever panel future-me happens to have.
PHIL_MODE="2560x1440@59.95"
PHIL_W=2560
PHIL_H=1440
XR_MODE="1920x1080"
XR_W=1920
XR_H=1080

require_jq() {
    command -v jq >/dev/null 2>&1 || {
        echo "ERROR: jq is required (sudo pacman -S jq)" >&2
        exit 1
    }
    command -v hyprctl >/dev/null 2>&1 || {
        echo "ERROR: hyprctl not found — is this a Hyprland session?" >&2
        exit 1
    }
}

# Globals populated by classify()
declare -A MON_DESC MON_W MON_H
LAPTOP=""; PHILIPS=""; GLASSES=""
OTHERS=()

classify() {
    local json
    json=$(hyprctl -j monitors all)

    while IFS=$'\t' read -r name desc w h; do
        MON_DESC[$name]="$desc"
        MON_W[$name]="$w"
        MON_H[$name]="$h"

        local lname=${name,,}
        local ldesc=${desc,,}

        if [[ $lname == edp* ]]; then
            LAPTOP="$name"
        elif [[ $ldesc == *xreal* || $ldesc == *nreal* ]]; then
            GLASSES="$name"
        elif [[ $ldesc == *philips* || $ldesc == *phl* ]]; then
            PHILIPS="$name"
        else
            OTHERS+=("$name")
        fi
    done < <(echo "$json" | jq -r '.[] | "\(.name)\t\(.description)\t\(.width)\t\(.height)"')

    # Fallback: identify Philips by its 2560x1440 native resolution if the
    # description match missed (e.g. EDID strings vary between firmware revs).
    if [[ -z $PHILIPS && ${#OTHERS[@]} -gt 0 ]]; then
        for i in "${!OTHERS[@]}"; do
            local n=${OTHERS[$i]}
            if [[ ${MON_W[$n]:-0} == 2560 && ${MON_H[$n]:-0} == 1440 ]]; then
                PHILIPS="$n"
                unset 'OTHERS[i]'
                OTHERS=("${OTHERS[@]}")
                break
            fi
        done
    fi
}

# Resolve a monitor's dimension, falling back to known constants if hyprctl
# reports 0/null (can happen for disabled monitors on some drivers).
dim() {
    local name="$1" axis="$2" v
    if [[ $axis == w ]]; then v="${MON_W[$name]:-0}"; else v="${MON_H[$name]:-0}"; fi
    if [[ -z $v || $v == 0 || $v == null ]]; then
        if   [[ $name == "$PHILIPS" ]]; then [[ $axis == w ]] && echo 2560 || echo 1440
        elif [[ $name == "$GLASSES" ]]; then [[ $axis == w ]] && echo 1920 || echo 1080
        else                                 [[ $axis == w ]] && echo 1920 || echo 1080
        fi
    else
        echo "$v"
    fi
}

report() {
    [[ -n $LAPTOP  ]] && echo "  Laptop:  $LAPTOP  (${MON_DESC[$LAPTOP]})"
    [[ -n $PHILIPS ]] && echo "  Philips: $PHILIPS  (${MON_DESC[$PHILIPS]})"
    [[ -n $GLASSES ]] && echo "  Glasses: $GLASSES  (${MON_DESC[$GLASSES]})"
    for o in "${OTHERS[@]}"; do
        echo "  Other:   $o  (${MON_DESC[$o]})"
    done
}

apply() {
    local name="$1" spec="$2"
    hyprctl keyword monitor "${name},${spec}" >/dev/null
    echo "  $name → $spec"
}

disable_monitor() {
    hyprctl keyword monitor "$1,disable" >/dev/null
    echo "  $1 → disabled"
}

mode_extend() {
    [[ -z $LAPTOP || -z $PHILIPS ]] && {
        echo "ERROR: extend mode needs laptop + Philips" >&2; exit 1; }

    # Philips portrait (transform=1, 90° CW): logical dims swap.
    local phil_lw=$PHIL_H   # logical width  = native height
    local phil_lh=$PHIL_W   # logical height = native width

    apply "$PHILIPS" "${PHIL_MODE},0x0,1,transform,1"

    # Laptop sits below the Philips column. x is clamped so the laptop
    # overlaps the Philips x-range (Hyprland requires monitors to touch).
    local laptop_x=$(( 795 < phil_lw - 1 ? 795 : phil_lw - 1 ))
    apply "$LAPTOP" "preferred,${laptop_x}x${phil_lh},1"

    if [[ -n $GLASSES ]]; then
        local y=$(( phil_lh - XR_H ))
        (( y < 0 )) && y=0
        apply "$GLASSES" "${XR_MODE},${phil_lw}x${y},1"
        for o in "${OTHERS[@]}"; do disable_monitor "$o"; done
    else
        echo "  (no glasses detected — use 'desk' for 2nd-monitor handling)"
        for o in "${OTHERS[@]}"; do disable_monitor "$o"; done
    fi
}

mode_desk() {
    [[ -z $LAPTOP || -z $PHILIPS ]] && {
        echo "ERROR: desk mode needs laptop + Philips" >&2; exit 1; }

    local phil_lw=$PHIL_H
    local phil_lh=$PHIL_W

    apply "$PHILIPS" "${PHIL_MODE},0x0,1,transform,1"
    local laptop_x=$(( 795 < phil_lw - 1 ? 795 : phil_lw - 1 ))
    apply "$LAPTOP" "preferred,${laptop_x}x${phil_lh},1"
    [[ -n $GLASSES ]] && disable_monitor "$GLASSES"

    if (( ${#OTHERS[@]} > 0 )); then
        local third=${OTHERS[0]}
        local th; th=$(dim "$third" h)
        local y=$(( phil_lh - th ))
        (( y < 0 )) && y=0
        apply "$third" "preferred,${phil_lw}x${y},1"
        for o in "${OTHERS[@]:1}"; do disable_monitor "$o"; done
    fi
}

mode_glasses_only() {
    [[ -z $GLASSES || -z $LAPTOP ]] && {
        echo "ERROR: glasses-only mode needs glasses + laptop" >&2; exit 1; }

    apply "$GLASSES" "${XR_MODE},0x0,1"
    apply "$LAPTOP"  "preferred,0x${XR_H},1"
    [[ -n $PHILIPS ]] && disable_monitor "$PHILIPS"
    for o in "${OTHERS[@]}"; do disable_monitor "$o"; done
}

status() {
    echo "=== Current display layout ==="
    hyprctl monitors
}

usage() {
    cat <<EOF
Usage: $0 <mode>

  extend          Philips (portrait) + Laptop + Glasses (right of Philips)
  desk            Philips (portrait) + Laptop (+ 2nd external if connected)
  glasses-only    Glasses (top) + Laptop (bottom)
  status          Show the current layout from hyprctl

Monitors are auto-detected by connector name (eDP*) and EDID description.
Layouts apply via 'hyprctl keyword monitor=...' and persist until reload.
EOF
}

main() {
    require_jq
    classify
    case "${1:-}" in
        extend)        report; mode_extend ;;
        desk)          report; mode_desk ;;
        glasses-only)  report; mode_glasses_only ;;
        status)        status; return ;;
        ""|-h|--help)  usage; exit 0 ;;
        *)             usage; exit 1 ;;
    esac
    echo
    status
}

main "$@"
