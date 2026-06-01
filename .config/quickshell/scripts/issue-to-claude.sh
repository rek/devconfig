#!/usr/bin/env bash
# Jump to a project's zellij tab in Alacritty and open a FRESH pane running
# `claude` primed with a prompt to read new comments on the given GH issue.
# Each invocation gets its own pane; we don't try to reuse an existing one
# (zellij has no good API to address a pane by name from outside).
#
# Usage:  issue-to-claude.sh <tab-name> <issue-url>
set -euo pipefail

TAB="${1:?need tab name}"
URL="${2:?need issue URL}"

hyprctl dispatch focuswindow '^(Alacritty)$' >/dev/null 2>&1 || true

# Switch to the tab (create if missing). The new pane gets opened inside it.
if zellij action query-tab-names 2>/dev/null | grep -Fxq "$TAB"; then
    zellij action go-to-tab-name "$TAB"
else
    zellij action new-tab --name "$TAB"
    sleep 0.3
fi

# Spawn a new pane running claude with the prompt as its first user message.
# Wrapping in `bash -lc` and passing the prompt via positional $1 keeps us
# safe from $-expansion / quote weirdness in the URL.
PROMPT="read new comments on this gh issue: $URL"
zellij action new-pane -- bash -lc 'claude "$1"' _ "$PROMPT"
