#!/usr/bin/env bash
# Print "on" if audio is routed to headphones, else "off".
# Used to drive the active state of the PHONES launcher button.
#
# 2026-07-05: Now reads the ALSA 'Headphone' mixer switch instead of the card
# profile — output switching is done at the mixer level since the Headphones
# UCM profile became unusable (see headphone-toggle.sh).
set -euo pipefail

if amixer -c sofhdadsp sget Headphone 2>/dev/null | grep -q '\[on\]'; then
    echo on
else
    echo off
fi
