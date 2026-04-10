#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# XReal Pro display setup for Ubuntu (Wayland / GNOME / Mutter)
# ─────────────────────────────────────────────────────────────────────────────
#
# Displays are auto-detected by vendor/product EDID info via the
# org.gnome.Mutter.DisplayConfig D-Bus interface (see xreal-apply-triple.py):
#
#   Philips  = 2560x1440, placed portrait-left at (0, 0)
#   Laptop   = eDP-* internal panel, primary, below Philips
#   XReal    = 1920x1080 glasses, placed to the right of Philips
#   Other    = any extra external monitor takes the "third" slot when
#              glasses aren't plugged in (reproduces the old 3-monitor layout)
#
# ─── Modes ───────────────────────────────────────────────────────────────────
#
#   triple          Philips + laptop + glasses, glasses run breezy-desktop
#                   virtual canvas. See WARNING below — this hijacks DRM.
#   extend          Philips + laptop + glasses, glasses act as a normal
#                   1920x1080 DisplayPort monitor. Does NOT touch xr_driver_cli.
#   desk            No glasses: Philips + laptop, plus a 2nd external monitor
#                   if it's plugged in.
#   install-breezy  One-shot installer for breezy-desktop.
#   status          Print xrandr's view of the current layout.
#
# ─── WARNING: xr_driver_cli kills the other physical monitors ────────────────
#
# On this machine, the XReal glasses already enumerate as a plain 1920x1080
# DisplayPort monitor as soon as the cable is plugged in — no userspace driver
# is needed to use them as a regular extended screen.
#
# Calling `~/.local/bin/xr_driver_cli --enable` (and the follow-up mode
# selectors --external-mode / --breezy-desktop / --virtual-display) while
# the glasses are in this plain-DP state causes mutter to drop the other
# physical outputs: the laptop's eDP-1 and the Philips DP-3 go completely
# dark. They remain "logically active" in GetCurrentState with the correct
# modes, but the physical panels get no signal. Calling --disable /
# --disable-external does NOT restore them — the only recovery is to
# re-apply a mutter layout via D-Bus (e.g. `./xreal-setup.sh desk`, which
# usually needs one Philips+laptop-only apply first to kick the DRM outputs
# awake, then a second apply to add the glasses back).
#
# That is why `extend` mode deliberately does NOT call xr_driver_cli — it
# just applies the mutter layout and leaves the driver alone. Only `triple`
# touches xr_driver_cli, and it intentionally accepts the hijack because
# breezy-desktop IS supposed to take over the DRM outputs (virtual wide
# canvas inside the glasses is a full-immersion mode).
#
# Discovered 2026-04-10 — do not "helpfully" add xr_driver_cli calls to
# `extend` or `desk` thinking it'll make the glasses work better. It won't.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

status() {
    echo "=== Current display layout ==="
    xrandr --query | grep " connected" | awk '{print "  " $1 ": " $3 " " $4}'
}

xr_enable_breezy() {
    if [ -x "$HOME/.local/bin/xr_driver_cli" ]; then
        "$HOME/.local/bin/xr_driver_cli" --enable
        "$HOME/.local/bin/xr_driver_cli" --breezy-desktop
        echo "XR driver: breezy-desktop enabled"
        echo "NOTE: breezy-desktop hijacks DRM — laptop & Philips panels will go dark."
    fi
}

case "${1:-}" in

  triple|extend|desk)
    mode="$1"
    # Python script auto-detects displays by vendor/product via D-Bus
    output=$(/usr/bin/python3 "$(dirname "$0")/xreal-apply-triple.py")
    echo "$output"
    if [ "$mode" = "triple" ] && echo "$output" | grep -q "HAS_GLASSES"; then
        xr_enable_breezy
    fi
    status
    ;;

  # ── Install breezy-desktop (virtual multi-monitor inside glasses) ──────────
  install-breezy)
    echo "=== Installing breezy-desktop ==="
    echo ""
    echo "breezy-desktop creates a large virtual desktop inside the glasses."
    echo "You pan left/right with head movement to see different screens."
    echo ""

    # Check for curl
    if ! command -v curl &>/dev/null; then
        sudo apt-get install -y curl
    fi

    echo "Downloading breezy-desktop installer (GNOME/Ubuntu x86_64)..."
    LATEST=$(curl -s "https://api.github.com/repos/wheaney/breezy-desktop/releases/latest" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
    echo "Latest version: $LATEST"
    curl -L --output /tmp/breezy_gnome_setup \
        "https://github.com/wheaney/breezy-desktop/releases/download/${LATEST}/breezy_gnome_setup"
    chmod +x /tmp/breezy_gnome_setup

    echo ""
    echo "Running installer (may ask for sudo)..."
    bash /tmp/breezy_gnome_setup

    echo ""
    echo "After install:"
    echo "  1. Run: breezy-desktop"
    echo "  2. Glasses will show a wide virtual canvas"
    echo "  3. Move your head to pan between virtual screens"
    echo "  4. Use the breezy UI to set number of screens (2, 3, etc.)"
    ;;

  # ── Status ─────────────────────────────────────────────────────────────────
  status)
    status
    ;;

  *)
    echo "Usage: $0 <mode>"
    echo ""
    echo "  triple          Philips + Laptop + Glasses (glasses = breezy-desktop)"
    echo "  extend          Philips + Laptop + Glasses (glasses = normal 3rd monitor)"
    echo "  desk            Philips + Laptop (+ 2nd monitor if plugged in), no glasses"
    echo "  install-breezy  Install breezy-desktop (virtual screens in glasses)"
    echo "  status          Show current layout"
    echo ""
    echo "Displays are auto-detected — no need to know connector names."
    echo "See the header comment in this script for the xr_driver_cli gotcha."
    ;;
esac
