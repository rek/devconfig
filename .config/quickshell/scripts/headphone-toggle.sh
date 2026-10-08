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

# Make sure PipeWire is actually routing to the laptop codec: the card on its
# Speaker profile (the Headphones profile is permanently unavailable), and the
# Speaker sink as default (it can fall back to HDMI when the profile drifts).
route_to_codec() {
    local card sink
    card=$(pactl list short cards | awk '/skl_hda_dsp_generic/ {print $2; exit}')
    [[ -n "$card" ]] || return 0
    pactl set-card-profile "$card" "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)" 2>/dev/null || true
    sink=$(pactl list short sinks | awk '/HiFi__Speaker__sink/ {print $2; exit}')
    [[ -n "$sink" ]] || return 0
    pactl set-default-sink "$sink" 2>/dev/null || true
    pactl set-sink-mute "$sink" 0 2>/dev/null || true
    local i
    for i in $(pactl list short sink-inputs | cut -f1); do
        pactl move-sink-input "$i" "$sink" 2>/dev/null || true
    done
}

apply() {
    local mode=$1
    route_to_codec
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
