#!/bin/bash
# Arch / Omarchy / Hyprland version of the dropdown-term installer.
# Counterpart of bin/setup-dropdown-term.gnome.sh (Ubuntu / GNOME / ddterm).
#
# One-shot installer for the CapsLock dropdown terminal on Omarchy.
#   keyd: remaps CapsLock -> F13 at evdev (Wayland-safe)
#   pyprland: scratchpad daemon, slides a ghostty window down on F13
#   ghostty: terminal in the scratchpad, with bottom tabs (ddterm-style)
#            and DDTERM=1 set so .zshrc skips the zellij auto-attach
#
# User-side configs are committed in this repo and assumed already in place:
#   ~/.config/pypr/config.toml          (pyprland scratchpads — new path)
#   ~/.config/hypr/{bindings.conf,autostart.conf}
#   ~/.config/ghostty/config            (gtk-tabs-location=bottom etc.)
#
# Run from a real terminal (sudo needs a TTY):
#   ~/dev/devconfig/bin/setup-dropdown-term.sh
set -e

echo "--- Installing keyd + pyprland + ghostty (dropdown terminal)..."
omarchy pkg add keyd ghostty
omarchy pkg aur add pyprland

echo "--- Writing /etc/keyd/default.conf..."
sudo install -d /etc/keyd
printf '[ids]\n*\n\n[main]\ncapslock = f13\n' | sudo tee /etc/keyd/default.conf >/dev/null

echo "--- Enabling keyd.service..."
sudo systemctl enable --now keyd

echo "--- Reloading Hyprland..."
hyprctl reload
hyprctl configerrors

echo "--- Starting pypr (will also autostart on next login)..."
pgrep -x pypr >/dev/null || setsid -f uwsm-app -- pypr >/dev/null 2>&1
sleep 1
pgrep -af pypr || echo "WARN: pypr not running"

echo ""
echo "Done. Tap CapsLock to toggle the dropdown terminal."
