#!/usr/bin/env bash
# Claude Code usage stats from ~/.claude/projects/*/*.jsonl transcripts.
# All token counts use Anthropic's billing-token weighting (cache_read counted
# at 0.1× — matches what /status shows).
#
# Three buckets:
#   SONNET = 7-day rolling, sonnet models only
#   ALL    = 7-day rolling, all models  (matches "All models" in /status)
#   NOW    = the active 5-hour block (matches "Current session" in /status)
#
# 5h blocks: anchored at the *top of the hour* of the first activity after the
# previous block ended; each block runs for 5 hours. This matches ccusage's and
# (best-effort) Anthropic's convention.
#
# Caps come from env vars. Defaults calibrated for default_claude_max_5x;
# adjust until the bars match /status.
set -euo pipefail

FIELD="${1:-all}"

exec python3 - "$FIELD" <<'PY'
import json, os, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

LIMITS = {
    'sonnet':  int(os.environ.get('CC_LIMIT_SONNET_WEEKLY', 270_000_000)),
    'all':     int(os.environ.get('CC_LIMIT_ALL_WEEKLY',    270_000_000)),
    'session': int(os.environ.get('CC_LIMIT_SESSION_5H',     40_000_000)),
}
RESET_ANCHOR = os.environ.get('CC_WEEKLY_RESET', 'TUE 08:44')
WEEK_DAYS = 7
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
events = sorted(collect(), key=lambda e: e[0])

# ---- weekly aggregates ----
week_start = now - timedelta(days=WEEK_DAYS)
sonnet_wk = 0
all_wk = 0
for ts, model, t in events:
    if ts >= week_start:
        all_wk += t
        if 'sonnet' in (model or '').lower():
            sonnet_wk += t

# ---- active 5h block (top-of-hour anchored) ----
block_start = block_end = None
block_tok = 0
for ts, _, t in events:
    if block_start is None or ts >= block_end:
        block_start = ts.replace(minute=0, second=0, microsecond=0)
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

if field == 'state':
    print('ACTIVE' if block_start else 'IDLE')
elif field == 'remaining':
    print(fmt_remaining((next_weekly_reset() - now).total_seconds()))
elif field == 'progress':       print(pct(all_wk, 'all'))
elif field == 'balance':        print(fmt(max(0, LIMITS['all'] - all_wk)))
elif field == 'sonnet':         print(fmt(sonnet_wk))
elif field == 'all':            print(fmt(all_wk))
elif field == 'session':        print(fmt(block_tok))
elif field == 'sonnet-pct':     print(pct(sonnet_wk, 'sonnet'))
elif field == 'all-pct':        print(pct(all_wk,    'all'))
elif field == 'session-pct':    print(pct(block_tok, 'session'))
elif field == 'session-reset':
    if not block_end: print('--')
    else: print(fmt_remaining((block_end - now).total_seconds()))
else:
    print('--')
PY
