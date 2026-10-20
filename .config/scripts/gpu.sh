#!/usr/bin/env bash
# NVIDIA GPU utilization %, for the HUD sparkline. nvidia-smi briefly wakes
# the dGPU, so this is polled on a relaxed interval. Prints 0 if the GPU is
# unavailable (driver issue, fully powered off).
set -euo pipefail

val=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null \
        | head -1 | tr -dc '0-9')
echo "${val:-0}"
