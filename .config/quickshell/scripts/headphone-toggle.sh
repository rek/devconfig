#!/usr/bin/env bash
# Switch audio between headphones and speakers at the ALSA mixer level.
#
# 2026-07-05: This used to toggle between the "HiFi (... Headphones ...)" and
# "HiFi (... Speaker)" card profiles, but since the kernel 7.0.9 update
# WirePlumber refuses to link sinks whose jack reports unplugged (this
# machine's headphone jack detection is broken, so the Headphones profile is
# permanently "available: no" and PulseAudio clients hang on it — Blender
# froze at startup). Both outputs live on the same PCM and differ only by
# codec mixer switches, so we now stay on the always-working Speaker profile
# and flip the 'Speaker'/'Headphone' switches directly. The card runs with
# api.alsa.soft-mixer = true (see wireplumber.conf.d/51-headphone-autoswitch.conf),
# so PipeWire does volume in software and never fights these settings.
#
# Usage: headphone-toggle.sh [toggle|phones|speakers|--apply]
#   toggle     flip between modes (default; wired to the PHONES button)
#   --apply    reapply the saved mode (used by headphone-mode.service at login,
#              because profile activation re-runs the UCM enable sequence
#              which turns the Speaker switch back on)
set -euo pipefail

CARD="sofhdadsp"
MODE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/headphone-mode"

current_mode() {
    if amixer -c "$CARD" sget Headphone | grep -q '\[on\]'; then
        echo phones
    else
        echo speakers
    fi
}

apply() {
    local mode=$1
    # Fixed baseline — soft-mixer means nothing else manages these.
    amixer -q -c "$CARD" sset Master 100% unmute
    amixer -q -c "$CARD" sset Speaker 100%
    amixer -q -c "$CARD" sset Headphone 100%
    if [[ "$mode" == phones ]]; then
        amixer -q -c "$CARD" sset Headphone unmute
        amixer -q -c "$CARD" sset Speaker mute
        # UCM uses DRC for speakers only
        amixer -q -c "$CARD" cset name='Post Mixer Analog Playback DRC switch' off 2>/dev/null || true
    else
        amixer -q -c "$CARD" sset Speaker unmute
        amixer -q -c "$CARD" sset Headphone mute
        amixer -q -c "$CARD" cset name='Post Mixer Analog Playback DRC switch' on 2>/dev/null || true
    fi
    mkdir -p "$(dirname "$MODE_FILE")"
    echo "$mode" > "$MODE_FILE"
}

case "${1:-toggle}" in
    phones|speakers)
        apply "$1" ;;
    --apply)
        apply "$(cat "$MODE_FILE" 2>/dev/null || echo speakers)" ;;
    toggle|*)
        if [[ "$(current_mode)" == phones ]]; then
            apply speakers
        else
            apply phones
        fi ;;
esac
