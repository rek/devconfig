-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Pyprland — scratchpad daemon for dropdown terminal (bound to F13 via keyd)
o.launch_on_start("pypr")

-- Sci-fi stats HUD on the laptop monitor (RAM + DL on the background layer)
o.launch_on_start("eww daemon")
o.exec_on_start([[sleep 1 && eww open-many stats-hud claude-hud]])

-- Quickshell HUDs (stats, tgt PRs, needs-reply issues). Loads ~/.config/quickshell.
-- The tgt PR HUD inside reacts to mode-state.sh and shows only in work mode.
o.launch_on_start("quickshell")
