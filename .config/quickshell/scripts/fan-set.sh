#!/usr/bin/env bash
# Set the MSI fan profile from the launcher's FAN group.
#
#   fan-set.sh silent|auto|advanced
#                            set fan_mode and drop cooler boost (boost
#                            overrides the mode, so picking a mode while
#                            boosting would otherwise look like a no-op).
#                            auto also starts fan-governor.service; the
#                            others stop it.
#   fan-set.sh boost         toggle cooler boost (fans pinned to max)
#
# Writing needs the udev rule etc/udev/rules.d/99-msi-ec-fan.rules, which
# hands these sysfs files to the wheel group. Without it, notify and bail.
set -uo pipefail
EC=/sys/devices/platform/msi-ec

fail() {
    notify-send -u critical "Fan control" "$1"
    exit 1
}

[[ -d $EC ]] || fail "msi-ec isn't loaded (sudo modprobe msi-ec)."
[[ -w $EC/fan_mode && -w $EC/cooler_boost ]] \
    || fail "No write access to msi-ec — install etc/udev/rules.d/99-msi-ec-fan.rules."

case "${1:-}" in
    silent|auto|advanced)
        # Stop the governor first so its exit doesn't race our writes.
        systemctl --user stop fan-governor.service 2>/dev/null
        echo off > "$EC/cooler_boost"
        echo "$1" > "$EC/fan_mode"
        # AUTO = firmware curve + the governor (bin/fan-governor), which adds
        # boost when the CPU runs hot.
        [[ $1 == auto ]] && systemctl --user start fan-governor.service
        ;;
    boost)
        if [[ $(cat "$EC/cooler_boost") == on ]]; then
            echo off > "$EC/cooler_boost"
        else
            echo on > "$EC/cooler_boost"
        fi
        ;;
    *)
        echo "usage: $0 silent|auto|advanced|boost" >&2
        exit 2
        ;;
esac
