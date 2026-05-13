#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Synced multi-monitor TTE screensaver for Omarchy / Hyprland.
# Replaces `omarchy-launch-screensaver` in our hypridle.conf so every monitor
# shows the SAME tte effect this session (upstream uses --random-effect,
# which makes each monitor pick independently and look different).
#
# Picks one effect at random per session. Next time the screensaver fires,
# a new random effect is chosen — but within a session, all monitors match.
#
# Single-file design with two modes:
#   no args  → outer launcher, picks effect and spawns inner on each monitor
#   `inner`  → loop running tte with the chosen effect (one per monitor)
# ─────────────────────────────────────────────────────────────────────────────

set -u

SCREENSAVER_CLASS="org.omarchy.screensaver"
BRANDING_TXT="${HOME}/.config/omarchy/branding/screensaver.txt"

# ── Inner mode ──────────────────────────────────────────────────────────────
# Runs inside each monitor's screensaver terminal. The effect is passed via
# OMARCHY_SS_EFFECT so all monitors share it.
if [[ ${1:-} == "inner" ]]; then
    EFFECT=${OMARCHY_SS_EFFECT:-matrix}

    screensaver_in_focus() {
        hyprctl activewindow -j | jq -e ".class == \"${SCREENSAVER_CLASS}\"" >/dev/null 2>&1
    }

    exit_screensaver() {
        hyprctl keyword cursor:invisible false &>/dev/null || true
        pkill -x tte 2>/dev/null
        pkill -f "${SCREENSAVER_CLASS}" 2>/dev/null
        exit 0
    }

    trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

    printf '\033]11;rgb:00/00/00\007'  # black background
    hyprctl keyword cursor:invisible true &>/dev/null
    tty=$(tty 2>/dev/null)

    while true; do
        # --random-effect + --include-effects with a single name forces tte
        # to pick that effect every loop iteration. Matches the upstream
        # call shape so flags like --frame-rate work identically.
        tte -i "$BRANDING_TXT" \
            --frame-rate 120 --canvas-width 0 --canvas-height 0 \
            --reuse-canvas --anchor-canvas c --anchor-text c \
            --random-effect --include-effects "$EFFECT" \
            --no-eol --no-restore-cursor &

        while pgrep -t "${tty#/dev/}" -x tte >/dev/null; do
            if read -n1 -t 1 || ! screensaver_in_focus; then
                exit_screensaver
            fi
        done
    done
    exit 0
fi

# ── Outer launcher ──────────────────────────────────────────────────────────

command -v tte >/dev/null 2>&1 || exit 1

# Don't double-launch. Check by window presence (not cmdline grep) so we
# don't false-positive on the caller shell having the class string in its
# own argv.
hyprctl clients -j 2>/dev/null \
    | jq -e --arg c "$SCREENSAVER_CLASS" '.[] | select(.class == $c)' >/dev/null \
    && exit 0

# Respect omarchy-toggle-enabled screensaver-off, allow `force` to bypass
if command -v omarchy-toggle-enabled >/dev/null 2>&1 \
   && omarchy-toggle-enabled screensaver-off 2>/dev/null \
   && [[ ${1:-} != "force" ]]; then
    exit 1
fi

# Pick ONE random effect for this session — all monitors will use it.
EFFECTS=(beams binarypath blackhole bouncyballs bubbles burn colorshift
         crumble decrypt errorcorrect expand fireworks highlight matrix
         middleout orbittingvolley overflow pour print rain randomsequence
         rings scattered slice slide smoke spotlights spray swarm sweep
         synthgrid thunderstorm unstable vhstape waves wipe)
EFFECT=${EFFECTS[RANDOM % ${#EFFECTS[@]}]}

walker -q 2>/dev/null || true

focused=$(omarchy-hyprland-monitor-focused 2>/dev/null \
          || hyprctl activeworkspace -j | jq -r '.monitor')
terminal=$(xdg-terminal-exec --print-id 2>/dev/null || echo ghostty)
SELF=$(readlink -f "$0")

for m in $(hyprctl monitors -j | jq -r '.[].name'); do
    hyprctl dispatch focusmonitor "$m"
    case "$terminal" in
        *ghostty*)
            hyprctl dispatch exec -- \
                ghostty --class="${SCREENSAVER_CLASS}" \
                --config-file="${HOME}/.local/share/omarchy/default/ghostty/screensaver" \
                --font-size=18 \
                -e env OMARCHY_SS_EFFECT="$EFFECT" "$SELF" inner
            ;;
        *Alacritty*)
            hyprctl dispatch exec -- \
                alacritty --class="${SCREENSAVER_CLASS}" \
                --config-file "${HOME}/.local/share/omarchy/default/alacritty/screensaver.toml" \
                -e env OMARCHY_SS_EFFECT="$EFFECT" "$SELF" inner
            ;;
        *foot*)
            hyprctl dispatch exec -- \
                foot --app-id="${SCREENSAVER_CLASS}" \
                --config="${HOME}/.local/share/omarchy/default/foot/screensaver.ini" \
                -e env OMARCHY_SS_EFFECT="$EFFECT" "$SELF" inner
            ;;
        *kitty*)
            hyprctl dispatch exec -- \
                kitty --class="${SCREENSAVER_CLASS}" \
                --override font_size=18 \
                --override window_padding_width=0 \
                -e env OMARCHY_SS_EFFECT="$EFFECT" "$SELF" inner
            ;;
        *)
            notify-send -u low "✋  Screensaver only runs in Alacritty, Foot, Ghostty, or Kitty"
            ;;
    esac
done

hyprctl dispatch focusmonitor "$focused"
