#!/usr/bin/env bash
# Print the currently active mode (work/home/none) for the WORK/HOME button
# highlight. The buttons write this state file directly; we fall back to the
# legacy hypr/modes/current.conf symlink so a fresh boot still reflects the
# last `mode` command before the user has clicked anything.
set -euo pipefail

state="$HOME/.local/state/eww-mode"
link="$HOME/.config/hypr/modes/current.conf"

if [[ -r $state ]]; then
    cat "$state"
elif [[ -L $link ]]; then
    target=$(readlink "$link")
    echo "${target%.conf}"
else
    echo none
fi
