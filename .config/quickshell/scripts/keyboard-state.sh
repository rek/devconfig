#!/usr/bin/env bash
# Lily58 state for the quickshell HUD. Thin shim over the generic
# `zmk-kb-status` (bin/zmk-kb-status, symlinked into ~/.local/bin by the
# installers) — all the BlueZ probing lives there; see docs/zmk-kb-status.md.
#
# Output is unchanged: "<link>|<Lpct>|<Rpct>", e.g. "usb|85|72".
#
# The MAC and USB serial are passed explicitly rather than autodetected: the
# serial pins the *left* half specifically, so "usb" means the left is wired
# rather than just any ZMK board being plugged in.

exec zmk-kb-status \
    --format plain \
    --mac E8:0C:B3:F6:66:10 \
    --usb-serial 3A8F02D9AD37EF58
