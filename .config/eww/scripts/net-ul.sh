#!/usr/bin/env bash
# Print upload rate in MB/s, summed across non-loopback interfaces.
# Mirrors net-dl.sh but reads TX bytes (column 11 in /proc/net/dev after the iface field).
set -euo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/eww-net-ul.state"
INTERVAL="${1:-1}"

TX=$(awk -F'[: ]+' '/:/ && $2 != "lo" {sum += $11} END {print sum+0}' /proc/net/dev)

if [[ -f $STATE ]]; then
    read -r PREV < "$STATE"
    DELTA=$(( TX - PREV ))
    (( DELTA < 0 )) && DELTA=0
else
    DELTA=0
fi
echo "$TX" > "$STATE"

awk -v d="$DELTA" -v i="$INTERVAL" 'BEGIN {printf "%.2f", (d/i)/1048576}'
