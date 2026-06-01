#!/usr/bin/env bash
# Claude Code usage stats from ~/.claude/projects/*/*.jsonl transcripts.
# All token counts use Anthropic's billing-token weighting (cache_read counted
# at 0.1× — matches what /status shows).
#
# Three buckets:
#   SONNET = since the weekly reset, sonnet models only
#   WEEKLY = since the weekly reset, all models  (matches "All models" in the UI)
#   NOW    = the active 5-hour block (matches "Current session" in the UI)
#
# 5h blocks: anchored at the first activity timestamp after the previous block
# ended; each block runs for exactly 5 hours from that point. Matches what the
# Claude usage UI shows for "Current session" reset time.
#
# Caps come from env vars. Defaults calibrated for default_claude_max_5x;
# adjust until the bars match /status.
set -euo pipefail

FIELD="${1:-all}"

# Shared cache. The six eww defpolls all call this script every 20–30s; without
# a cache each does a full transcript scan (~1s of CPU). Instead the first call
# in a TTL window does ONE scan, computes EVERY field, and writes them here;
# the rest are served from this file without spawning python at all.
CACHE="${XDG_RUNTIME_DIR:-/tmp}/cc-usage.cache"
LOCK="$CACHE.lock"
TTL=30

serve_cache() {  # print FIELD from the cache; return 1 if cache/field absent
  [[ -f "$CACHE" ]] || return 1
  local line
  line=$(grep -m1 -F "$FIELD"$'\t' "$CACHE" 2>/dev/null) || return 1
  printf '%s\n' "${line#*$'\t'}"
}

# Fresh cache → serve immediately, no python.
if [[ -f "$CACHE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
  if (( age >= 0 && age < TTL )); then
    if serve_cache; then exit 0; fi
  fi
fi

# Stale/missing cache. The five 20s pollers were started together by the eww
# daemon, so they fire in lockstep — without a lock they'd all miss at the same
# instant and launch five concurrent transcript scans every TTL window (the
# ~200% spikes). Double-checked locking: serialize on fd 9, and once we hold the
# lock RE-CHECK the cache — a concurrent winner has usually just refreshed it, so
# the losers serve that fresh value instead of each running their own scan.
exec 9>"$LOCK"
if ! flock -w 5 9; then
  # Couldn't get the lock in time — serve whatever cache exists rather than hang.
  serve_cache || echo '--'
  exit 0
fi
if [[ -f "$CACHE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
  if (( age >= 0 && age < TTL )); then
    if serve_cache; then exit 0; fi
  fi
fi

# We hold the lock and the cache is genuinely stale — we're the one scan.
python3 - "$FIELD" "$CACHE" <<'PY'
import json, os, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

LIMITS = {
    'sonnet':  int(os.environ.get('CC_LIMIT_SONNET_WEEKLY', 270_000_000)),
    'all':     int(os.environ.get('CC_LIMIT_ALL_WEEKLY',    385_000_000)),
    'session': int(os.environ.get('CC_LIMIT_SESSION_5H',     46_000_000)),
}
RESET_ANCHOR = os.environ.get('CC_WEEKLY_RESET', 'TUE 08:44')
BLOCK = timedelta(hours=5)

field = sys.argv[1]
PROJECTS = Path.home() / '.claude' / 'projects'

def parse_ts(s):
    return datetime.fromisoformat(s.replace('Z', '+00:00')) if s else None

def billing_tokens(u):
    return (u.get('input_tokens', 0)
            + u.get('output_tokens', 0)
            + u.get('cache_creation_input_tokens', 0)
            + u.get('cache_read_input_tokens', 0) * 0.1)

def collect():
    for jsonl in PROJECTS.glob('*/*.jsonl'):
        try:
            with open(jsonl) as f:
                for line in f:
                    try: d = json.loads(line)
                    except Exception: continue
                    if d.get('type') != 'assistant': continue
                    m = d.get('message') or {}
                    if not isinstance(m, dict): continue
                    ts = parse_ts(d.get('timestamp'))
                    if ts is None: continue
                    yield (ts, m.get('model','unknown'),
                           billing_tokens(m.get('usage') or {}))
        except Exception:
            continue

def fmt(n):
    n = int(n)
    if n >= 1_000_000: return f'{n/1_000_000:.1f}M'
    if n >= 1_000:     return f'{n/1_000:.1f}K'
    return str(n)

now = datetime.now(timezone.utc)

def next_weekly_reset():
    DOW = {'MON':0,'TUE':1,'WED':2,'THU':3,'FRI':4,'SAT':5,'SUN':6}
    parts = RESET_ANCHOR.upper().split()
    try:
        td = DOW[parts[0]]
        h, m = (int(x) for x in parts[1].split(':'))
    except Exception:
        td, h, m = 0, 0, 0
    local_now = datetime.now().astimezone()
    days_ahead = (td - local_now.weekday()) % 7
    cand = local_now.replace(hour=h, minute=m, second=0, microsecond=0) \
                    + timedelta(days=days_ahead)
    if cand <= local_now:
        cand += timedelta(days=7)
    return cand.astimezone(timezone.utc)

def fmt_remaining(secs):
    secs = max(0, int(secs))
    if secs == 0: return '0m'
    d, rem = divmod(secs, 86400)
    h, rem = divmod(rem, 3600)
    m, _ = divmod(rem, 60)
    if d:    return f'{d}d {h}h'
    if h:    return f'{h}h {m:02d}m'
    return f'{m}m'

events = sorted(collect(), key=lambda e: e[0])

# ---- weekly aggregates (since the last weekly reset, matching the usage UI) ----
week_start = next_weekly_reset() - timedelta(days=7)
sonnet_wk = 0
all_wk = 0
for ts, model, t in events:
    if ts >= week_start:
        all_wk += t
        if 'sonnet' in (model or '').lower():
            sonnet_wk += t

# ---- active 5h block (anchored at first activity timestamp) ----
block_start = block_end = None
block_tok = 0
for ts, _, t in events:
    if block_start is None or ts >= block_end:
        block_start = ts
        block_end = block_start + BLOCK
        block_tok = t
    else:
        block_tok += t
# If the latest block has already expired, there's no active session.
if block_end is not None and now >= block_end:
    block_start = block_end = None
    block_tok = 0

def pct(val, key):
    cap = LIMITS[key]
    return min(100, int(val / cap * 100)) if cap else 0

# One scan, every field — so the shared cache lets all six pollers ride a single
# transcript scan per TTL window instead of each doing its own.
out = {
    'state':         'ACTIVE' if block_start else 'IDLE',
    'remaining':     fmt_remaining((next_weekly_reset() - now).total_seconds()),
    'progress':      str(pct(all_wk, 'all')),
    'balance':       fmt(max(0, LIMITS['all'] - all_wk)),
    'sonnet':        fmt(sonnet_wk),
    'all':           fmt(all_wk),
    'session':       fmt(block_tok),
    'sonnet-pct':    str(pct(sonnet_wk, 'sonnet')),
    'all-pct':       str(pct(all_wk, 'all')),
    'session-pct':   str(pct(block_tok, 'session')),
    'session-reset': '--' if not block_end
                     else fmt_remaining((block_end - now).total_seconds()),
}

# Persist the whole field set atomically (write-then-rename) so a concurrent
# poller never reads a half-written cache. Best-effort: a cache failure must
# not break the widget, so fall through to printing on any error.
cache_path = sys.argv[2] if len(sys.argv) > 2 else None
if cache_path:
    try:
        tmp = f'{cache_path}.{os.getpid()}.tmp'
        with open(tmp, 'w') as f:
            for k, v in out.items():
                f.write(f'{k}\t{v}\n')
        os.replace(tmp, cache_path)
    except Exception:
        pass

print(out.get(field, '--'))
PY
