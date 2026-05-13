#!/usr/bin/env bash
# Print download rate in MB/s, summed across non-loopback interfaces.
# Expects to be polled on a fixed interval (default 1s). The state file
# carries previous RX bytes; delta divided by interval seconds = bytes/sec.
set -euo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/eww-net-dl.state"
INTERVAL="${1:-1}"

# RX bytes from all interfaces except loopback. /proc/net/dev: first
# numeric column after the iface name is bytes received.
RX=$(awk -F'[: ]+' '/:/ && $2 != "lo" {sum += $3} END {print sum+0}' /proc/net/dev)

if [[ -f $STATE ]]; then
    read -r PREV < "$STATE"
    DELTA=$(( RX - PREV ))
    (( DELTA < 0 )) && DELTA=0
else
    DELTA=0
fi
echo "$RX" > "$STATE"

awk -v d="$DELTA" -v i="$INTERVAL" 'BEGIN {printf "%.2f", (d/i)/1048576}'
