#!/usr/bin/env bash
# Print the currently active mode (work/home/none) for the WORK/HOME button
# highlight. The buttons write this state file directly; until one is clicked
# the answer is "none".
set -euo pipefail

state="$HOME/.local/state/mode"

if [[ -r $state ]]; then
    cat "$state"
else
    echo none
fi
