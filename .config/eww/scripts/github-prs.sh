#!/usr/bin/env bash
# Open PRs authored by the current user on maiella-io/tgt, with rolled-up CI
# status, as JSON for the HUD. `gh` hits the GitHub API, so results are cached.
#
# Output: [{"number","title","url","ci"}] where ci is pass|fail|pending|none.
set -euo pipefail

REPO="maiella-io/tgt"
CACHE="${XDG_RUNTIME_DIR:-/tmp}/eww-github-prs.json"
CACHE_TTL=300

if [[ -f $CACHE ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
    (( age < CACHE_TTL )) && { cat "$CACHE"; exit 0; }
fi

raw=$(gh pr list --repo "$REPO" --author "@me" --state open \
        --json number,title,url,statusCheckRollup 2>/dev/null || true)
[[ -z $raw ]] && raw='[]'

python3 - "$raw" <<'PY' | tee "$CACHE"
import json, sys

prs = json.loads(sys.argv[1])

# Roll a PR's individual checks into one of pass|fail|pending|none.
# fail wins over pending wins over pass; no checks at all -> none.
def rollup(checks):
    any_pending = any_pass = False
    for c in checks or []:
        t = c.get('__typename')
        if t == 'CheckRun':
            if c.get('status') != 'COMPLETED':
                any_pending = True
            elif c.get('conclusion') in ('SUCCESS', 'NEUTRAL', 'SKIPPED'):
                any_pass = True
            else:
                return 'fail'
        elif t == 'StatusContext':
            s = c.get('state')
            if s == 'PENDING':
                any_pending = True
            elif s == 'SUCCESS':
                any_pass = True
            else:
                return 'fail'
    if any_pending: return 'pending'
    if any_pass:    return 'pass'
    return 'none'

out = [{'number': p['number'], 'title': p['title'], 'url': p['url'],
        'ci': rollup(p.get('statusCheckRollup'))} for p in prs]
print(json.dumps(out))
PY
