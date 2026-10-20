#!/usr/bin/env bash
# Print "on" if hyprsunset is running with the night-light temperature set
# (matches omarchy's ON_TEMP=4000), else "off". Used to drive the active
# state of the NIGHT launcher button.
set -euo pipefail

if ! pgrep -x hyprsunset >/dev/null; then
    echo off
    exit 0
fi

temp=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+' | head -1 || echo 6000)
if [[ "$temp" -le 5000 ]]; then
    echo on
else
    echo off
fi
