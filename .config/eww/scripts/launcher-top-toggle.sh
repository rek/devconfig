#!/usr/bin/env bash
# Flip the launcher always-on-top state (on/off). When on, the overlay-layer
# window `launcher-hud-top` is opened (renders above fullscreen apps); when off,
# the foreground-layer window `launcher-hud` is opened. State is persisted so it
# survives eww reloads.
set -euo pipefail

STATE="$HOME/.local/state/eww-launcher-top"
cur=$(cat "$STATE" 2>/dev/null || echo off)
new=$([[ $cur == on ]] && echo off || echo on)

printf '%s\n' "$new" > "$STATE"
eww update launcher-top="$new"

if [[ $new == on ]]; then
  eww close launcher-hud 2>/dev/null || true
  eww open launcher-hud-top
else
  eww close launcher-hud-top 2>/dev/null || true
  eww open launcher-hud
fi
