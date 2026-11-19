#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Display setup for Omarchy / Arch (Hyprland / Wayland)
#
# Handles laptop + Philips external + XReal Pro glasses (+ any 2nd external).
# ─────────────────────────────────────────────────────────────────────────────
#
# Auto-detects monitors via `hyprctl -j monitors all`:
#
#   Laptop  — connector name starts with eDP
#   Philips — description matches "Philips" / "PHL" (fallback: any 2560x1440)
#   Glasses — description matches "XREAL" / "Nreal"
#   Other   — anything else; fills the "third" slot in desk mode
#   (virtual/headless outputs such as CAPTURE are ignored and left as they are)
#
# Modes:
#
#   extend          Philips (portrait) + Laptop + Glasses (glasses right of Philips)
#   desk            Philips (portrait) + Laptop (+ 2nd external if connected)
#   home            External (landscape, top) + Laptop (bottom), horizontally centered
#   glasses-only    Glasses (top) + Laptop (bottom)
#   laptop          Laptop only (disables everything else)
#   auto            Pick one of the above from what's plugged in
#   status          One line per monitor: on/off, size, position, name
#
# Add -n / --dry-run to any mode to print what it would do without touching
# Hyprland or the runtime file. After applying, the script checks every monitor
# it enabled is really on and warns if one is still dark.
#
# Layouts are applied live via `hyprctl eval 'hl.monitor({…})'` AND persisted to
# ~/.config/hypr/monitors-runtime.lua (a Lua module on Hyprland's package.path,
# loaded by monitors.lua), so they survive Hyprland config reloads. Re-run this
# script when you plug/unplug hardware or want to switch modes.
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
# enumerate as 1920x1080.
#
# The laptop panel used to stay on `preferred` so this script would work on
# whatever panel future-me happens to have — but `preferred` resolves to
# 2560x1600@240, and driving a 240Hz panel costs ~25W of GPU on an idle
# desktop (measured 2026-08-14: 45%/47W at 240Hz vs 14%/19W at 60Hz, worth
# ~20°C of CPU package temp on this shared-heatpipe chassis). Nothing on this
# desktop benefits from 240Hz.
#
# Override to go back, either permanently here or per-invocation:
#   LAPTOP_MODE=preferred display-setup.sh <mode>
LAPTOP_MODE="${LAPTOP_MODE:-2560x1600@60}"
PHIL_MODE="2560x1440@59.95"
PHIL_W=2560
PHIL_H=1440
XR_MODE="1920x1080@120"
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

RUNTIME_FILE="${HOME}/.config/hypr/monitors-runtime.lua"

# Globals populated by classify()
declare -A MON_DESC MON_W MON_H
LAPTOP=""; PHILIPS=""; GLASSES=""
OTHERS=()

# Accumulates monitor= lines applied this run, flushed to RUNTIME_FILE at the end.
RUNTIME_LINES=()
WANT_ON=()      # monitors this run asked to enable, checked by verify()
DRY_RUN=0

classify() {
    local json
    json=$(hyprctl -j monitors all)

    # Fields are split on the ASCII unit separator, not a tab: tab is IFS
    # whitespace, so `read` collapses consecutive tabs and an empty description
    # (every virtual output) shifts the fields left. That bug made CAPTURE2/3
    # look like real monitors and got the office Acer disabled (2026-11-19).
    while IFS=$'\x1f' read -r name desc w h; do
        # Virtual outputs are not screens: skip them so no mode ever lays out,
        # disables or persists them. CAPTURE is the headless monitor test runs
        # draw on (makektm games tools/display/offscreen.sh); Hyprland's default
        # headless names are HEADLESS-N. A headless output has no EDID, so an
        # empty description is the catch-all. Without this, an unrecognised
        # real monitor (an office Acer) and CAPTURE share the OTHERS list and
        # whichever sorts second gets disabled, CAPTURE included (2026-11-12).
        if [[ $name == CAPTURE* || $name == HEADLESS-* || -z $desc ]]; then
            continue
        fi
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
    done < <(echo "$json" | jq -r '.[] | [.name, .description, .width, .height] | map(tostring) | join("\u001f")')

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

    # Only use PHIL_MODE if the Philips is actually offering it right now.
    # Through some docks/cables it only advertises up to 1920x1080, and asking
    # for 2560x1440 anyway makes the atomic commit fail (EINVAL) in a loop:
    # nothing gets applied (not even the portrait transform) and aquamarine
    # can crash the session. Fall back to its best advertised mode instead.
    if [[ -n $PHILIPS ]]; then
        local modes
        modes=$(echo "$json" | jq -r --arg n "$PHILIPS" \
            '.[] | select(.name == $n) | .availableModes[]')
        if [[ -n $modes ]] && ! grep -qF "$PHIL_MODE" <<< "$modes"; then
            local best=${modes%%$'\n'*}
            echo "  Philips not offering $PHIL_MODE — using ${best%Hz}" >&2
            PHIL_MODE=${best%Hz}
            PHIL_W=${PHIL_MODE%%x*}
            PHIL_H=${PHIL_MODE#*x}; PHIL_H=${PHIL_H%@*}
        fi
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
    # `hyprctl keyword` only works with the legacy .conf parser; Omarchy's
    # Quatro release switched Hyprland to the native Lua config, so live
    # monitor changes now go through `hyprctl eval` calling hl.monitor()
    # directly. spec is "mode,position,scale[,transform,N]".
    local mode position scale transform_lit transform_val
    IFS=',' read -r mode position scale transform_lit transform_val <<< "$spec"
    local lua="hl.monitor({ output = \"${name}\", mode = \"${mode}\", position = \"${position}\", scale = ${scale}"
    if [[ ${transform_lit:-} == transform ]]; then
        lua+=", transform = ${transform_val}"
    fi
    lua+=" })"
    run_eval "$lua"
    RUNTIME_LINES+=("${name}|${mode}|${position}|${scale}|${transform_val:-}")
    WANT_ON+=("$name")
    echo "  $name → $spec"
}

disable_monitor() {
    # The field is `disabled`, not `disable` — Hyprland's Lua binding rejects
    # `disable` with "unknown field 'disable'" and the monitor stays on.
    run_eval "hl.monitor({ output = \"$1\", disabled = true })"
    RUNTIME_LINES+=("${1}|disabled||")
    echo "  $1 → disabled"
}

# Send one Lua snippet to Hyprland. Prints it instead under --dry-run, and
# warns (rather than silently continuing) if Hyprland answers anything but "ok".
run_eval() {
    if (( DRY_RUN )); then
        echo "  [dry-run] $1"
        return
    fi
    local out
    out=$(hyprctl eval "$1" 2>&1) || true
    [[ $out == ok ]] || echo "  WARN: hyprctl eval said: ${out:-<nothing>}" >&2
}

# After applying, confirm every monitor we asked for is really on. A monitor
# can be accepted by the config yet stay dark (bad cable, mode rejected).
verify() {
    (( DRY_RUN )) && return
    sleep 1.5
    local json bad=0 n
    json=$(hyprctl -j monitors all)
    for n in "${WANT_ON[@]}"; do
        if [[ $(jq -r --arg n "$n" '.[] | select(.name == $n) | .disabled' <<< "$json") != false ]]; then
            echo "  WARN: $n was asked to turn on but is still disabled" >&2
            bad=1
        fi
    done
    (( bad )) && echo "  Check the cable/dock, or run '$0 status'." >&2
    return 0
}

write_runtime_file() {
    if (( DRY_RUN )); then
        echo; echo "(dry run: nothing applied, $RUNTIME_FILE untouched)"
        return
    fi
    {
        echo "-- Auto-generated by scripts/display-setup.sh — do not edit by hand."
        echo "-- Persists the current monitor layout across Hyprland reloads."
        echo "-- Re-run \`display-setup.sh <mode>\` to update."
        echo
        echo "local M = {}"
        echo
        echo "M.monitors = {"
        for line in "${RUNTIME_LINES[@]}"; do
            IFS='|' read -r name mode position scale transform <<< "$line"
            if [[ $mode == "disabled" ]]; then
                echo "  { output = \"${name}\", disabled = true },"
            else
                entry="  { output = \"${name}\", mode = \"${mode}\", position = \"${position}\", scale = ${scale}"
                [[ -n $transform ]] && entry+=", transform = ${transform}"
                echo "${entry} },"
            fi
        done
        echo "}"
        echo
        echo "return M"
    } > "$RUNTIME_FILE"
    echo
    echo "Persisted layout → $RUNTIME_FILE"
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
    apply "$LAPTOP" "${LAPTOP_MODE},${laptop_x}x${phil_lh},1"

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
    apply "$LAPTOP" "${LAPTOP_MODE},${laptop_x}x${phil_lh},1"
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

mode_home() {
    # Any single external works here, not just the Philips: home isn't always
    # the same desk (e.g. a 1920x1080 Acer). Prefer the Philips if present,
    # else the first unrecognised external at its own preferred mode and
    # current size — hard-coding 1440 for a 1080 panel leaves a dead gap
    # between it and the laptop that the cursor can't cross.
    [[ -z $LAPTOP ]] && { echo "ERROR: no laptop detected" >&2; exit 1; }
    local ext ext_mode mw mh
    if [[ -n $PHILIPS ]]; then
        ext=$PHILIPS; ext_mode=$PHIL_MODE; mw=$PHIL_W; mh=$PHIL_H
    elif (( ${#OTHERS[@]} > 0 )); then
        ext=${OTHERS[0]}; ext_mode=preferred
        mw=$(dim "$ext" w); mh=$(dim "$ext" h)
        OTHERS=("${OTHERS[@]:1}")
    else
        echo "  (no external monitor detected — laptop only)"
        [[ -n $GLASSES ]] && disable_monitor "$GLASSES"
        apply "$LAPTOP" "${LAPTOP_MODE},0x0,1"
        return
    fi

    local lw; lw=$(dim "$LAPTOP" w)

    # Center the narrower monitor horizontally; the wider one anchors at x=0.
    local mon_x=0 laptop_x=0
    if (( lw > mw )); then
        mon_x=$(( (lw - mw) / 2 ))
    elif (( mw > lw )); then
        laptop_x=$(( (mw - lw) / 2 ))
    fi

    apply "$ext" "${ext_mode},${mon_x}x0,1"
    apply "$LAPTOP"  "${LAPTOP_MODE},${laptop_x}x${mh},1"

    [[ -n $GLASSES ]] && disable_monitor "$GLASSES"
    for o in "${OTHERS[@]}"; do disable_monitor "$o"; done
}

mode_glasses_only() {
    [[ -z $GLASSES || -z $LAPTOP ]] && {
        echo "ERROR: glasses-only mode needs glasses + laptop" >&2; exit 1; }

    apply "$GLASSES" "${XR_MODE},0x0,1"
    apply "$LAPTOP"  "${LAPTOP_MODE},0x${XR_H},1"
    [[ -n $PHILIPS ]] && disable_monitor "$PHILIPS"
    for o in "${OTHERS[@]}"; do disable_monitor "$o"; done
}

mode_laptop() {
    [[ -z $LAPTOP ]] && { echo "ERROR: no laptop detected" >&2; exit 1; }

    # Disable secondaries first so the laptop doesn't briefly overlap them at 0x0.
    [[ -n $GLASSES ]] && disable_monitor "$GLASSES"
    [[ -n $PHILIPS ]] && disable_monitor "$PHILIPS"
    for o in "${OTHERS[@]}"; do disable_monitor "$o"; done

    apply "$LAPTOP" "${LAPTOP_MODE},0x0,1"
}

status() {
    echo "=== Current display layout ==="
    hyprctl -j monitors all | jq -r '
        .[] | (if .disabled then "off" else "on " end) as $s
        | "  \($s)  \(.name)\t\(if .disabled then "-" else "\(.width)x\(.height)@\(.refreshRate | . * 100 | round / 100) at \(.x)x\(.y)" end)\t\(.description | if . == "" then "(virtual)" else . end)"' \
        | column -t -s $'\t'
}

# Pick the layout that fits whatever is plugged in right now.
mode_auto() {
    local pick
    if   [[ -n $PHILIPS ]];                 then pick=desk
    elif (( ${#OTHERS[@]} > 0 ));           then pick=home
    elif [[ -n $GLASSES ]];                 then pick=glasses-only
    else                                         pick=laptop
    fi
    echo "  auto → $pick"
    "mode_${pick//-/_}"
}

usage() {
    cat <<EOF
Usage: $0 [-n|--dry-run] <mode>

  auto            Pick the best layout for what's plugged in right now
  extend         Philips (portrait) + Laptop + Glasses (right of Philips)
  desk            Philips (portrait) + Laptop (+ 2nd external if connected)
  home            External (landscape, top) + Laptop (bottom), horizontally centered
  glasses-only    Glasses (top) + Laptop (bottom)
  laptop          Laptop only (disables everything else)
  status          Show the current layout from hyprctl

Monitors are auto-detected by connector name (eDP*) and EDID description.
Layouts apply live via 'hyprctl eval hl.monitor({...})' and persist to
~/.config/hypr/monitors-runtime.lua so they survive a Hyprland reload.
EOF
}

main() {
    local args=()
    for a in "$@"; do
        case $a in
            -n|--dry-run) DRY_RUN=1 ;;
            *)            args+=("$a") ;;
        esac
    done
    set -- "${args[@]}"

    require_jq
    classify
    case "${1:-}" in
        auto)          report; mode_auto ;;
        extend)        report; mode_extend ;;
        desk)          report; mode_desk ;;
        home)          report; mode_home ;;
        glasses-only)  report; mode_glasses_only ;;
        laptop)        report; mode_laptop ;;
        status)        status; return ;;
        ""|-h|--help)  usage; exit 0 ;;
        *)             usage; exit 1 ;;
    esac
    write_runtime_file
    verify
    echo
    status
}

main "$@"
