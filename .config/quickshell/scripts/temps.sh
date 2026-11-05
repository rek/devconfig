#!/usr/bin/env bash
# CPU + GPU temperatures for the quickshell Temp HUD.
# Output: "<epoch>|<cpuC>|<gpuC>"   e.g. "1762300000|72|48"
#   The epoch makes every line unique, so the Poller's valueChanged fires on
#   every sample even when both temps are unchanged — and lets the HUD plot by
#   real time instead of by sample count.
#   "--" stands in for a sensor that isn't available (no x86_pkg_temp zone,
#   dGPU powered off / driver down).
cpu=$(~/.config/scripts/cpu-temp.sh 2>/dev/null || echo "--")
gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null \
        | head -1 | tr -dc '0-9')
echo "${EPOCHSECONDS}|${cpu}|${gpu:---}"
