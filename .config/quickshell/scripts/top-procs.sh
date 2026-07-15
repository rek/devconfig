#!/usr/bin/env bash
# Top processes by CPU% for the quickshell Top CPU HUD.
# Output: one process per line, "pid|cpu|mem|name", top 15 by %CPU — the HUD
# slices to however many rows its count setting wants, so this always fetches
# the max (15) rather than re-templating the command per setting change.

ps -eo pid,pcpu,pmem,comm --sort=-pcpu --no-headers | head -n 15 | awk '{print $1"|"$2"|"$3"|"$4}'
