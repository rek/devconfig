#!/usr/bin/env bash
# Flip the PR HUD always-on-top state (on/off). When on, the overlay-layer
# window `pr-hud-top` is opened (renders above fullscreen apps); when off,
# the foreground-layer window `pr-hud` is opened. State is persisted so it
# survives eww reloads.
set -euo pipefail

STATE="$HOME/.local/state/eww-pr-top"
cur=$(cat "$STATE" 2>/dev/null || echo off)
new=$([[ $cur == on ]] && echo off || echo on)

printf '%s\n' "$new" > "$STATE"
eww update pr-top="$new"

if [[ $new == on ]]; then
  eww close pr-hud 2>/dev/null || true
  eww open pr-hud-top
else
  eww close pr-hud-top 2>/dev/null || true
  eww open pr-hud
fi
