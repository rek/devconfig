#!/usr/bin/env bash
# Wrapper for eww/quickshell launcher buttons. Spawning commands as direct
# children of eww/quickshell lacks Hyprland's session env — so apps like
# nautilus never see the compositor properly. Routing through Hyprland's
# exec dispatcher runs under the same path as keybinding `exec`, which is
# what we want.
#
# Uses `hyprctl eval` + hl.dsp.exec_cmd, not `hyprctl dispatch exec <cmd>`:
# Omarchy's Quatro release switched Hyprland to native Lua config, and
# `hyprctl dispatch` now tries to parse its argument as a Lua expression
# instead of the old space-separated dispatcher syntax, so the legacy form
# silently errors.
cmd="$*"
escaped=${cmd//\\/\\\\}
escaped=${escaped//\"/\\\"}
exec hyprctl eval "hl.dispatch(hl.dsp.exec_cmd(\"${escaped}\"))" >/dev/null
