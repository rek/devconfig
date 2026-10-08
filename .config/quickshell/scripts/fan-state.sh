#!/usr/bin/env bash
# Print "<fan_mode>|<cooler_boost>|<rpm>" for the launcher's FAN group,
# e.g. "auto|off|3934". rpm is the faster of the two fans (CPU/GPU).
#
# Mode + boost come from msi-ec (AUR msi-ec-dkms-git, loaded via
# etc/modules-load.d/msi-ec.conf). RPM comes from msi_wmi_platform's hwmon —
# looked up by name since hwmon numbering isn't stable across boots.
EC=/sys/devices/platform/msi-ec

mode=$(cat "$EC/fan_mode" 2>/dev/null || echo "--")
boost=$(cat "$EC/cooler_boost" 2>/dev/null || echo "off")

rpm=0
for h in /sys/class/hwmon/hwmon*; do
    [[ $(cat "$h/name" 2>/dev/null) == msi_wmi_platform ]] || continue
    for f in "$h"/fan[12]_input; do
        v=$(cat "$f" 2>/dev/null || echo 0)
        (( v > rpm )) && rpm=$v
    done
done

echo "$mode|$boost|$rpm"
