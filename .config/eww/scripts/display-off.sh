#!/usr/bin/env bash
# Lock, then let the platform blank the display. Steam etc. keep running in
# the background since this only locks (doesn't suspend).
#
# We used to force `hyprctl dispatch dpms off` ourselves right after locking.
# Don't: the omarchy.lock Quickshell service (Service.qml) already arms its
# own 5s idleBlankTimer the instant a lock starts, and blanks via the same
# path `omarchy brightness display off` uses (hl.dsp.dpms({action=disable})).
# Firing dpms off ourselves before that timer's stabilization window elapses
# races the session-lock surface still settling — Quickshell sees it as a
# monitor change, re-requests the lock surface, and Hyprland powers the
# display back on to show it. Net effect: blank for ~2s, then back to the
# lock screen lit. Just locking and letting the built-in timer run avoids
# the race entirely — display goes dark ~5s later instead of instantly.

omarchy-system-lock
