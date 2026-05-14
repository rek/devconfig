#!/usr/bin/env bash
# Print the currently active Hyprland mode (work/home/none) for the
# HUD buttons. Reads the modes/current.conf symlink target.
set -euo pipefail

link="$HOME/.config/hypr/modes/current.conf"
if [[ -L "$link" ]]; then
    target=$(readlink "$link")
    echo "${target%.conf}"
else
    echo none
fi
