-- Workspace → monitor bindings + mode-agnostic window rules.
-- Monitor names assume desk mode (laptop + Philips + Acer). A rule for an
-- absent monitor is silently ignored, so this is safe across modes.
--
-- Per-class launch placement lives in ~/.config/hypr/modes/<mode>.conf,
-- selected via the `mode` command.

hl.workspace_rule({ workspace = "1", monitor = "eDP-2", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", default = true })

-- Pyprland dropdown terminal: force it floating so the scratchpad shows as an
-- overlay instead of tiling into the layout. pyprland normally floats it
-- itself, but that regressed (Hyprland now spawns the special-workspace window
-- tiled), so pin it here.
o.window({ class = [[^(dropdown\.term)$]] }, { float = true })

-- Blender's Save As / Open file browser spawns a SEPARATE window (class
-- "blender") at a hardcoded 320x240 — tiny. It opens titled "File Browser"
-- then renames itself to "Blender File View"; we must match the OPEN-time
-- title ("File Browser") so the static size/center rules fire at creation.
-- Reuse Omarchy's floating-window primitive (float + center + size 875x600,
-- defined in default/hypr/apps/system.lua) so it behaves like every other
-- save/open dialog. Title match keeps the main editor (same class) untouched.
o.window({
  class = "^(blender)$",
  title = "^(File Browser|Blender File View)$",
}, { tag = "+floating-window" })
