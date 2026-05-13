#!/usr/bin/env bash
# CPU usage % across all cores, delta-based against a state file.
# /proc/stat first line: cpu user nice system idle iowait irq softirq steal ...
set -euo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/eww-cpu.state"

read -r _ U N S I IO IR SI ST _ < /proc/stat
TOTAL=$((U + N + S + I + IO + IR + SI + ST))

OUT=0
if [[ -f $STATE ]]; then
    read -r PT PI < "$STATE"
    DT=$((TOTAL - PT))
    DI=$((I - PI))
    if (( DT > 0 )); then
        OUT=$(awk -v dt="$DT" -v di="$DI" 'BEGIN { printf "%.0f", (1 - di/dt) * 100 }')
    fi
fi
echo "$TOTAL $I" > "$STATE"
echo "$OUT"
