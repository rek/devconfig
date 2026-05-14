#!/usr/bin/env bash
# Force-refresh the PR HUD: drop the cache, re-fetch, push straight into eww
# (the periodic defpoll would otherwise wait out its interval).
set -euo pipefail

rm -f "${XDG_RUNTIME_DIR:-/tmp}/eww-github-prs.json"
eww update github-prs="$(~/.config/eww/scripts/github-prs.sh)"
