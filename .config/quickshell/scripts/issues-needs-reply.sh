#!/usr/bin/env bash
# Open issues on a GitHub repo whose last activity is NOT from `me` —
# i.e. waiting on a reply from us. Last activity = last comment, falling back
# to the issue's author if no comments exist yet.
#
# Usage:  issues-needs-reply.sh <owner/repo> [me]
#         issues-needs-reply.sh rek/alphaTilesAgain rek
#         issues-needs-reply.sh rek/parakeet         # me defaults to gh login
#
# Cache file: /tmp/qs-issues-needs-reply-<owner-repo>.json (50s TTL).
# Output: [{"number","title","url","ci"}]. `ci` is always "none" — present so
# PrItem can render this without modification.
set -euo pipefail

REPO="${1:?need repo (owner/name)}"
ME="${2:-$(gh api user --jq '.login' 2>/dev/null || echo '')}"

CACHE="/tmp/qs-issues-needs-reply-${REPO//\//-}.json"
CACHE_TTL=50

if [[ -f $CACHE ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
    (( age < CACHE_TTL )) && { cat "$CACHE"; exit 0; }
fi

raw=$(gh issue list --repo "$REPO" --state open --limit 50 \
        --json number,title,url,author,comments 2>/dev/null || true)
[[ -z $raw ]] && raw='[]'

python3 - "$raw" "$ME" <<'PY' | tee "$CACHE"
import json, sys

issues = json.loads(sys.argv[1])
me = sys.argv[2]

out = []
for i in issues:
    comments = i.get('comments') or []
    if comments:
        last = (comments[-1].get('author') or {}).get('login') or ''
    else:
        last = (i.get('author') or {}).get('login') or ''
    if last != me:
        out.append({
            'number': i['number'],
            'title':  i['title'],
            'url':    i['url'],
            'ci':     'none',
        })

print(json.dumps(out))
PY
