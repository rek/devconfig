-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Application bindings
o.bind("SUPER + RETURN", "Terminal", [[uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"]])
o.bind("SUPER + ALT + RETURN", "Tmux", [[uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" bash -c "tmux attach || tmux new -s Work"]])
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + F", "File manager", "uwsm-app -- nautilus --new-window")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", [[uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"]])
o.bind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", "omarchy-launch-or-focus-tui cliamp")
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + SHIFT + D", "Docker", "omarchy-launch-tui lazydocker")
o.bind("SUPER + SHIFT + G", "Signal", [[omarchy-launch-or-focus ^signal$ "uwsm-app -- signal-desktop"]])
o.bind("SUPER + SHIFT + O", "Obsidian", [[omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian"]])
o.bind("SUPER + SHIFT + W", "Typora", "uwsm-app -- typora --enable-wayland-ime")
o.bind("SUPER + SHIFT + SLASH", "Passwords", "uwsm-app -- 1password")

-- If your web app url contains #, type it as ## to prevent hyprland treating it as a comment
o.bind("SUPER + SHIFT + A", "ChatGPT", [[omarchy-launch-webapp "https://chatgpt.com"]])
o.bind("SUPER + SHIFT + ALT + A", "Grok", [[omarchy-launch-webapp "https://grok.com"]])
o.bind("SUPER + SHIFT + C", "Calendar", [[omarchy-launch-webapp "https://app.hey.com/calendar/weeks/"]])
o.bind("SUPER + SHIFT + E", "Email", [[omarchy-launch-webapp "https://app.hey.com"]])
o.bind("SUPER + SHIFT + Y", "YouTube", [[omarchy-launch-webapp "https://youtube.com/"]])
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", [[omarchy-launch-or-focus-webapp WhatsApp "https://web.whatsapp.com/"]])
o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", [[omarchy-launch-or-focus-webapp "Google Messages" "https://messages.google.com/web/conversations"]])
o.bind("SUPER + SHIFT + P", "Google Photos", [[omarchy-launch-or-focus-webapp "Google Photos" "https://photos.google.com/"]])
o.bind("SUPER + SHIFT + X", "X", [[omarchy-launch-webapp "https://x.com/"]])
o.bind("SUPER + SHIFT + ALT + X", "X Post", [[omarchy-launch-webapp "https://x.com/compose/post"]])

-- Add extra bindings
o.bind("CTRL + ALT + 6", "Move window to next monitor", "/home/adam/.config/hypr/scripts/move-to-next-monitor.sh")
o.bind("CTRL + ALT + 7", "Tile with others on monitor", "/home/adam/.config/hypr/scripts/tile-with-others.sh")
o.bind("CTRL + ALT + 8", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("CTRL + ALT + 9", "Cycle to previous visible window", "hyprctl dispatch cyclenext 'prev visible'")
o.bind("CTRL + ALT + 0", "Cycle to next visible window", "hyprctl dispatch cyclenext visible")
o.bind("CTRL + ALT + Y", "Snap window to left half", "/home/adam/.config/hypr/scripts/snap-half.sh left")
o.bind("CTRL + ALT + U", "Snap window to right half", "/home/adam/.config/hypr/scripts/snap-half.sh right")

-- Dropdown terminal — CapsLock (keyd remaps caps→F13) toggles pyprland scratchpad.
-- Bind by evdev keycode (KEY_F13 = 183, xkb +8 = 191): the F13 keysym is not in
-- the active xkb keymap, so a plain F13 key name never matches.
o.bind("code:191", "Dropdown terminal", "pypr toggle term")

-- Screenshot: slurp a region, then satty opens with the crop tool so the
-- capture isn't finalized until you confirm. Overrides the default omarchy PRINT bind.
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot (crop in satty)", "/home/adam/.config/hypr/scripts/screenshot-crop.sh")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
