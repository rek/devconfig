#!/usr/bin/env bash
# Disk usage for the quickshell Disk HUD.
# Output: "<rootPct>|<rootUsed>|<rootSize>|<rootAvail>|<bootPct>|<bootUsed>|<bootSize>|<bootAvail>"
#   e.g. "99|934G|952G|11.5G|25|501M|2.0G|1.6G"
#   avail is formatted via numfmt for one-decimal precision — df -h rounds to
#   whole units above 10 (e.g. "12G"), which reads too coarse on the HUD.
#   root: / (also covers /home, pacman cache, /var/log here — same dm-mapper vol)
#   boot: /boot (separate nvme partition)

read -r rootPct rootUsed rootSize <<< "$(df -h --output=pcent,used,size / | tail -1 | tr -d '%')"
rootAvail=$(df -B1 --output=avail / | tail -1 | tr -d ' ' | numfmt --to=iec --format="%.1f")

if boot_line=$(df -h --output=pcent,used,size /boot 2>/dev/null | tail -1); then
    read -r bootPct bootUsed bootSize <<< "$(tr -d '%' <<< "$boot_line")"
    bootAvail=$(df -B1 --output=avail /boot | tail -1 | tr -d ' ' | numfmt --to=iec --format="%.1f")
else
    bootPct="--"; bootUsed="--"; bootSize="--"; bootAvail="--"
fi

echo "${rootPct}|${rootUsed}|${rootSize}|${rootAvail}|${bootPct}|${bootUsed}|${bootSize}|${bootAvail}"
