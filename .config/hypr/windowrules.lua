-- Mode-agnostic window rules.
--
-- No workspace -> monitor pins here: Omarchy gives each physical monitor its
-- own block of ten workspaces (default/hypr/monitor-workspaces.lua), and
-- number pins like "workspace 2 -> DP-2" fought that, pulling workspace 2 off
-- the laptop's block onto the external monitor.

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

-- Godot game test runs (agents capture screenshots / measure frame time, and
-- the games run windowed). They open on CAPTURE, a headless
-- virtual monitor created at startup (autostart.lua), so they render on the GPU
-- but never show on a real screen or steal focus. The Godot editor has class
-- "Godot" and is untouched. To play a game yourself, use
-- `tools/godot/play.sh apps/<game>` in the games repo: it pulls the window to
-- the monitor you're on.
hl.monitor({ output = "CAPTURE", mode = "1080x2340@60", position = "20000x20000", scale = 1 })
o.window(
  { class = [[^(Car Smasher|Game 6|Stunt Yard|Smash Sandbox|Balloons|Lane Shooter Two)$]] },
  -- float: tiled, each new test window split CAPTURE, and a few hung runs shrank later shots to
  -- 53x63 px (2026-11-12). Floating, each keeps the size Godot asks for.
  { monitor = "CAPTURE", no_initial_focus = true, float = true }
)
