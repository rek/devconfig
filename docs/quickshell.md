# Quickshell

Desktop HUDs on eDP-2 (`.config/quickshell/`), replacing the old eww HUDs.
Runs via `exec-once = uwsm-app -- quickshell` in `hypr/autostart.conf`, auto-loading
`~/.config/quickshell/shell.qml` (which resolves straight into this repo).

Launch manually: `quickshell` · Teardown: `pkill quickshell`

## Palette

Two color families coexist on purpose — don't invent a third:

- **Legacy green** (`#00ff88` on near-black, ~72% alpha) — the original HUDs:
  stats card, `KeyboardHud`, issues/PR cards. Hardcoded per-component, no
  shared singleton.
- **Synthwave/outrun** (magenta `#ff2bd6` / cyan `#00fff9`) — newer, used by
  the `Launcher`. Lives in `theme/Theme.qml` as a proper singleton
  (`import "../theme"; Theme.cyan`).

New widgets: pick whichever family fits where they sit. Anything next to the
stats card or KeyboardHud should stay green: for anything freestanding,
prefer the `Theme` singleton over hardcoding a third palette.

## Primitives

Framework-style — build a reusable component and compose, don't one-off:

- `Poller.qml` — periodic shell command → `value` string (eww `defpoll` equivalent)
- `FlipCard.qml` + `FlipGesture.qml` — two-faced card, 3D Y-axis flip on click
  and/or horizontal drag. Front/back are content slots (`front: [...]`,
  `back: [...]`), so a control declared inside keeps its own `id:` scope.
- `StatRow.qml`, `IconButton.qml`, `ToggleButton.qml`, `LaunchButton.qml`,
  `CassetteReel.qml` — small single-purpose display/control primitives, composed
  inside the bigger HUD cards rather than inlined.

## KeyboardHud

Lily58 split-keyboard link + per-half battery, styled as a spinning mixtape
(reel per half, spool size = battery %, "SIDE A/B" = link state). Data from
`scripts/keyboard-state.sh` → `link|Lpct|Rpct` (BLE battery-proxy details in
the script header).

- **Position**: top-right, directly below the `/sys/proc.metrics` stats card
  (`shell.qml`'s `statsCard`, which centers at `0.35 * screenHeight`). Used to
  live bottom-right above the Orca/Steam row — moved here 2026-07, replacing
  the old flat green box outright rather than running both.
- **Drag to flip, not click.** The old version opened ZMK Studio on click;
  once the card became a `FlipCard`, click and drag-to-flip would have
  fought over the same gesture. Front is drag-only (`clickFrontToFlip: false`);
  the ZMK Studio launcher moved to a button on the back face, alongside raw
  diagnostics (MAC, GATT characteristic, poll interval).

## Design gallery

`.config/quickshell-gallery/` and `.config/quickshell-gallery-demo/` — 24
from-scratch redesigns of KeyboardHud (keycap silhouette, PCB trace map, VU
meter, oscilloscope, LED bargraph, cassette tape, etc.), tiled across eDP-2
as a second, standalone quickshell instance so browsing them never touches
the live shell.

- `quickshell-gallery/` polls the real `keyboard-state.sh` (shows real state —
  can look "empty" if the keyboard's actually disconnected)
- `quickshell-gallery-demo/` feeds fixed, asymmetric demo values (`ble`,
  L 87%, R 23%) instead, so every cell renders full
- Each variant is `components/V##_NameCell.qml`, same three-prop interface
  (`link`, `lpct`, `rpct`, `accent`) — `shell.qml`'s `variants` array + a
  `Loader` tile them in a grid, so adding one is just a new file + one line
  in that array
- Launch: `quickshell -p ~/dev/devconfig/.config/quickshell-gallery[-demo]`
  Close: `pkill -f 'quickshell -p.*quickshell-gallery'`
- Deliberately self-contained (own copy of `Poller`/`FlipCard`/`FlipGesture`,
  no imports outside its own folder — quickshell won't load QML modules from
  outside a config's root anyway) so it's reusable/publishable on its own
  later. #20 (cassette tape) was picked and ported into the real
  `KeyboardHud`; the gallery stays as-is for future rounds.

## Known issue

`quickshell` (extra repo, 0.3.0-1) logs a Qt version-mismatch warning — built
against qt6-base 6.11.0, system's on 6.11.1. Not a local misconfiguration:
it's the latest available package on both sides, just a distro packaging
timing gap. Qt patch bumps are supposed to stay ABI-compatible and it's run
fine in practice — left alone rather than rebuilding from source.
