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

-- Fallback for any other/unlisted monitor.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
