#!/usr/bin/env bash
# GitHub-style contribution heatmap for Adam's commits across ~/dev repos.
#
# Output: JSON array of week-columns, each a 7-element array of day cells:
#   [ [ {"date","count","level"} x7 ] x WEEKS ]
# Row 0 = Sunday. Future days in the current week render as level 0.
#
# Scanning ~50 repos takes a few seconds, so results are cached and the eww
# poll runs on a relaxed interval.
set -euo pipefail

WEEKS=15
DEV_ROOT="$HOME/dev"
# git --author is a regex matched against "Name <email>". Cover Adam's identities.
AUTHOR='Adam Tombleson\|rekarnar@gmail\|rek@users'
CACHE="${XDG_RUNTIME_DIR:-/tmp}/eww-git-heatmap.json"
CACHE_TTL=600

if [[ -f $CACHE ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
    (( age < CACHE_TTL )) && { cat "$CACHE"; exit 0; }
fi

# Anchor the grid: Sunday of the week (WEEKS-1) weeks before this week.
dow_today=$(date +%w)                                  # 0=Sun .. 6=Sat
start_epoch=$(date -d "today -${dow_today} days -$((WEEKS - 1)) weeks" +%s)
start_date=$(date -d "@${start_epoch}" +%Y-%m-%d)

declare -A counts
while IFS= read -r gitdir; do
    repo=${gitdir%/.git}
    while IFS= read -r d; do
        [[ -n $d ]] && counts[$d]=$(( ${counts[$d]:-0} + 1 ))
    done < <(git -C "$repo" log --all --no-merges \
                 --author="$AUTHOR" --since="$start_date" \
                 --format=%cd --date=short 2>/dev/null || true)
done < <(find "$DEV_ROOT" -maxdepth 3 -name .git -type d 2>/dev/null)

level() {
    local c=$1
    if   (( c == 0 )); then echo 0
    elif (( c <= 2 )); then echo 1
    elif (( c <= 5 )); then echo 2
    elif (( c <= 9 )); then echo 3
    else                    echo 4
    fi
}

{
    printf '['
    for (( w = 0; w < WEEKS; w++ )); do
        (( w > 0 )) && printf ','
        printf '['
        for (( d = 0; d < 7; d++ )); do
            (( d > 0 )) && printf ','
            day=$(date -d "@$(( start_epoch + (w * 7 + d) * 86400 ))" +%Y-%m-%d)
            c=${counts[$day]:-0}
            printf '{"date":"%s","count":%d,"level":%d}' "$day" "$c" "$(level "$c")"
        done
        printf ']'
    done
    printf ']\n'
} | tee "$CACHE"
