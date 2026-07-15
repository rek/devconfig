#!/usr/bin/env bash
# Quick-reference folder sizes for the DiskHud back side.
# Output: one "label|size" line per folder, via `du -sh`.
#   Fixed list rather than configurable — this is a glance-only readout,
#   not a disk browser. Polled slowly (see DiskHud.qml) since `du` over
#   ~/dev's ~90G walks a lot of inodes.

folders=(
    "$HOME"
    "$HOME/dev"
    "$HOME/Downloads"
    "$HOME/Documents"
    "$HOME/.cache"
)

for f in "${folders[@]}"; do
    [[ -d "$f" ]] || continue
    size=$(du -sh "$f" 2>/dev/null | cut -f1)
    label="~${f#$HOME}"
    echo "${label}|${size:---}"
done
