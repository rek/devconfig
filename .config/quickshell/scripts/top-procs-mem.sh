#!/usr/bin/env bash
# Top processes by memory% for the quickshell Top Mem HUD. Same shape as
# top-procs.sh, just sorted by %MEM instead of %CPU.
# Output: one process per line, "pid|cpu|mem|name", top 15 by %MEM.

ps -eo pid,pcpu,pmem,comm --sort=-pmem --no-headers | head -n 15 | awk '{print $1"|"$2"|"$3"|"$4}'
