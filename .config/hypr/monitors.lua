-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Desk monitor (Philips 144Hz).
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Laptop panel. Pinned to 60Hz, not the panel's 240Hz maximum: driving 240Hz
-- costs ~25W of GPU on an idle desktop and ~20°C of CPU package temp (shared
-- heatpipe). See LAPTOP_MODE in scripts/display-setup.sh, which overrides
-- this live via `hyprctl keyword monitor=…` per mode.
hl.monitor({ output = "eDP-2", mode = "2560x1600@60", position = "0x1440", scale = 1 })

-- Home monitor (HKC 32E6QC), above the laptop panel. Only takes effect when
-- DP-2 is actually connected — Hyprland ignores this line otherwise, so
-- laptop-only sessions at home are unaffected. Without this pin, DP-2 fell
-- through to the "auto" fallback below, which places new monitors to the
-- side instead of above (broke `mode home`'s vertical layout on every
-- reload/reconnect until display-setup.sh ran again).
--
-- Position only — deliberately NOT a fixed mode. DP-2 is a port, not a
-- monitor: at work it is an Acer ED320QR S3 that has no 2560x1440 mode.
-- Pinning `2560x1440@59.95` there makes Hyprland request a custom mode the
-- panel rejects (atomic commit EINVAL, in a loop), and aquamarine 0.15.0
-- then dereferences a null pointer in restateConnectors and takes the whole
-- session down (2026-09-21, three crashes in three minutes). display-setup.sh
-- sets the real per-monitor modes live for `mode home` / `mode work`.
hl.monitor({ output = "DP-2", mode = "preferred", position = "0x0", scale = 1 })

-- Fallback for any other/unlisted monitor.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
