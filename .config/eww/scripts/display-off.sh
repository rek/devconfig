#!/usr/bin/env bash
# Turn off all displays without suspending the system. Steam etc. keep
# running in the background.
#
# Why we lock first:
#   hypridle.conf has a screensaver listener at 600s with
#     on-timeout = pidof hyprlock || $HOME/dev/devconfig/scripts/omarchy-screensaver-synced.sh
#   If hyprlock isn't running, the screensaver will fire while we're dark
#   and wake the display. Locking first short-circuits that check.
#   OMARCHY_LOCK_ONLY=true skips the lock script's own 3s brightness-off
#   scheduler — we're doing dpms off ourselves.

# Let the click event drain so it doesn't immediately wake the screen.
sleep 0.3

OMARCHY_LOCK_ONLY=true omarchy-system-lock

# Wait briefly for hyprlock to actually be up, so the screensaver pidof
# check will see it.
for _ in {1..20}; do
  pidof hyprlock >/dev/null && break
  sleep 0.1
done

hyprctl dispatch dpms off
