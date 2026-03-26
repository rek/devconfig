#!/bin/bash
# UserPromptSubmit / SessionEnd hook: detect PR from current branch
# peon.sh reads .pr-context.json to include PR # in tab title
set -uo pipefail

INPUT=$(cat)
STATE_FILE="${HOME}/.claude/hooks/.pr-context.json"

# Always pass through, even on error
trap 'echo "{\"continue\": true}"' EXIT

# Parse JSON fields
eval "$(echo "$INPUT" | python3 -c '
import json, sys, shlex
q = shlex.quote
try:
    d = json.load(sys.stdin)
    print("HOOK_EVENT=" + q(d.get("hook_event_name", "")))
    print("SID=" + q(d.get("session_id", "")))
    print("CWD=" + q(d.get("cwd", "")))
except Exception:
    print("HOOK_EVENT="); print("SID="); print("CWD=")
' 2>/dev/null)"

[ -z "$SID" ] && exit 0

# Helper: remove this session's entry from state file
clear_session() {
  python3 -c "
import json, os, sys
sf, sid = sys.argv[1], sys.argv[2]
try:
    state = json.load(open(sf))
except Exception:
    sys.exit(0)
state.get('sessions', {}).pop(sid, None)
if state.get('sessions'):
    json.dump(state, open(sf, 'w'))
else:
    try: os.remove(sf)
    except Exception: pass
" "$STATE_FILE" "$SID" 2>/dev/null || true
}

# --- SessionEnd: remove this session's entry ---
if [ "$HOOK_EVENT" = "SessionEnd" ]; then
  clear_session
  exit 0
fi

# --- Detect PR from current branch (works in worktrees too) ---
PR=""
[ -n "$CWD" ] && PR=$(cd "$CWD" && gh pr view --json number -q '.number' 2>/dev/null) || true

if [ -z "$PR" ]; then
  clear_session
  exit 0
fi

# --- Write PR to state file ---
python3 -c "
import json, os, sys, time
sf, sid, pr = sys.argv[1], sys.argv[2], int(sys.argv[3])
try:
    state = json.load(open(sf))
except Exception:
    state = {}
state.setdefault('sessions', {})[sid] = {'pr': pr, 'ts': time.time()}
json.dump(state, open(sf, 'w'))
" "$STATE_FILE" "$SID" "$PR" 2>/dev/null || true
