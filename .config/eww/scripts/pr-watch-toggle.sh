#!/usr/bin/env bash
# Flip the PR HUD watch state (on/off). Persisted to a state file so it
# survives eww reloads; also pushed to eww immediately for a snappy toggle.
set -euo pipefail

STATE="$HOME/.local/state/eww-pr-watch"
cur=$(cat "$STATE" 2>/dev/null || echo on)
new=$([[ $cur == on ]] && echo off || echo on)

printf '%s\n' "$new" > "$STATE"
eww update pr-watch="$new"
