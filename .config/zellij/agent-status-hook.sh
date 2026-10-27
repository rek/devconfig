#!/bin/sh
# zellij-agent-status v0.1.7
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

# Optional one-identity pin: if ~/.config/zellij/agent-status-plugin.url
# exists, its first line is the exact URL of the loaded plugin instance (the
# agent-status alias location in config.kdl) and the pipe targets only it.
# Keep it in sync with config.kdl — a --plugin URL that is not the running
# instance makes zellij launch a second copy of the plugin. Without the file
# the pipe broadcasts, reaching every running agent-status instance.
plugin_url=""
pin_file="${HOME}/.config/zellij/agent-status-plugin.url"
if [ -s "$pin_file" ]; then
  plugin_url=$(head -n 1 "$pin_file" 2>/dev/null || true)
fi

# Closed stdin: zellij pipe otherwise waits for payload on stdin.
# timeout: a missing plugin must never hang the agent.
if [ -n "$plugin_url" ]; then
  exec timeout 2 zellij pipe --plugin "$plugin_url" --name agent-status -- "${ZELLIJ_PANE_ID}:${state}" </dev/null >/dev/null 2>&1
else
  exec timeout 2 zellij pipe --name agent-status -- "${ZELLIJ_PANE_ID}:${state}" </dev/null >/dev/null 2>&1
fi

