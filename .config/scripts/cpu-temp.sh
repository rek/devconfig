#!/usr/bin/env bash
# Read CPU package temperature in °C from the x86_pkg_temp thermal zone.
# Falls back to "--" if the zone is missing on this hardware.
set -euo pipefail

for zone in /sys/class/thermal/thermal_zone*; do
    [[ -r "$zone/type" ]] || continue
    if [[ "$(cat "$zone/type")" == "x86_pkg_temp" ]]; then
        awk '{printf "%.0f", $1/1000}' "$zone/temp"
        exit 0
    fi
done
echo "--"
