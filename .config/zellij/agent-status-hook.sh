#!/bin/sh
# zellij-agent-status v0.1.5
# Drive zellij-agent-status from an agent hook (Claude Code or Grok).
# Usage: agent-status-hook.sh <working|waiting|done|idle|end|stop>
#
# `stop` reads hook JSON from stdin and maps Grok session teardown
# (`/exit` → reason shutdown|channel_closed) to `end`, so the tab
# badge clears instead of sticking on ✅.
set -eu

state=${1:-}
if [ -z "$state" ]; then
  echo "usage: $0 working|waiting|done|idle|end|stop" >&2
  exit 2
fi

if [ "$state" = stop ]; then
  reason=$(jq -r '.reason // empty' 2>/dev/null || true)
  case "$reason" in
    shutdown|channel_closed) state=end ;;
    *) state=done ;;
  esac
else
  cat >/dev/null 2>&1 || true
fi

[ -n "${ZELLIJ:-}" ] || exit 0
[ -n "${ZELLIJ_PANE_ID:-}" ] || exit 0

# One identity: the local wasm. Must match load_plugins and Alt+a.
# --plugin pins that URL so a leftover https/alias copy cannot hang the pipe.
# Closed stdin: zellij pipe otherwise waits for payload on stdin.
# timeout: a missing plugin must never hang the agent.
plugin="file:${HOME}/.config/zellij/plugins/zellij-agent-status.wasm"
exec timeout 2 zellij pipe --plugin "$plugin" --name agent-status -- "${ZELLIJ_PANE_ID}:${state}" </dev/null >/dev/null 2>&1

