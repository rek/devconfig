#!/usr/bin/env bash
# Wrapper for eww launcher buttons. eww's :onclick spawns commands as direct
# children of the eww process, which lacks Hyprland's session env — so apps
# like nautilus never see the compositor properly. Routing through
# `hyprctl dispatch exec` runs under the same path as keybinding `exec`,
# which is what we want.
exec hyprctl dispatch exec "$*" >/dev/null
