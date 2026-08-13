# zmk-kb-status

Link state and battery percentage for a ZMK keyboard, in whatever shape your
status bar wants. One script (`bin/zmk-kb-status`), no dependencies beyond the
`bluetoothctl` and `busctl` that BlueZ already installs.

The probing is bar-agnostic. Everything below is the same script with a
different `--format`.

## Formats

| `--format` | Output | For |
|---|---|---|
| `plain` (default) | `usb\|85\|72` | quickshell `Poller`, shell scripts |
| `text` | `󰈷 85 72` | GNOME panel extensions, tmux, polybar |
| `json` | `{"link":"usb","left":85,"right":72}` | anything that parses JSON |
| `waybar` | `{"text":"󰈷 85%","class":"usb","percentage":85}` | waybar custom module |

`link` is `usb`, `ble`, or `off`. Batteries are `--`/`null` when unknown.

Unibody boards report a single percentage and leave the right half empty. Split
boards get both halves, provided the firmware both fetches and proxies the
peripheral's battery:

```
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING=y
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY=y
```

A worked example, with the board-side reasoning and the BlueZ gotchas, is in
[keyboards/06 — Lily58](https://github.com/rek/keyboards/blob/main/06%20-%20lilly58/HOST-BATTERY.md).

## Configuration

Nothing is required — with no config it autodetects a connected BLE keyboard
advertising the battery service. To pin a specific board, use flags or
`~/.config/zmk-kb-status/config`:

```sh
ZMK_KB_MAC=E8:0C:B3:F6:66:10
ZMK_KB_USB_SERIAL=3A8F02D9AD37EF58   # optional; pins one half of a split
```

`--usb-serial` is worth setting on a split board: without it, `usb` means *some*
ZMK board is plugged in; with it, `usb` means that specific half is wired.
`--usb-id` overrides the VID:PID if the firmware doesn't use ZMK's default
`1d50:615e`. See `zmk-kb-status --help` for the rest.

## Recipe: waybar

```jsonc
// ~/.config/waybar/config
"custom/keyboard": {
  "exec": "zmk-kb-status --format waybar",
  "return-type": "json",
  "interval": 30,
  "tooltip": true
}
```

Add `"custom/keyboard"` to `modules-right`, then colour it by state:

```css
/* ~/.config/waybar/style.css */
#custom-keyboard.usb     { color: #00ff88; }
#custom-keyboard.ble     { color: #00ff88; }
#custom-keyboard.unknown { color: #ccaa44; }  /* connected, battery unreadable */
#custom-keyboard.off     { color: #446655; }
```

The icons are Nerd Font glyphs, so the bar needs a Nerd Font — swap them in the
script for plain text if not.

## Recipe: GNOME top bar

GNOME's panel can't run commands on its own, so it needs an extension that polls
one. [Executor](https://extensions.gnome.org/extension/2932/executor/) is the
usual pick; Argos works the same way. Add a command, set the interval, use the
`text` format:

```
zmk-kb-status --format text
```

That yields `󰈷 85 72` in the panel. Executor renders stdout verbatim, so any
formatting you want goes in the command — e.g. append `| cut -d' ' -f1-2` for
just the wired icon and the left half.

## Recipe: quickshell

`.config/quickshell/scripts/keyboard-state.sh` is a shim that calls this with
`--format plain`; `KeyboardHud.qml` polls the shim every 15s and splits on `|`.
The `plain` format exists to keep that contract stable.

## The `unknown` class

`link` is not `off` but no battery reads back. Almost always an unbonded BLE
connection: BlueZ reports `Connected: yes` but never resolves GATT, so
`org.bluez.Battery1` doesn't exist on the device object and there are no
characteristics to walk. Check with:

```sh
busctl get-property org.bluez /org/bluez/hci0/dev_<MAC> org.bluez.Device1 ServicesResolved
```

`false` means re-pair the keyboard. Note this is also the permanent state on
USB-only: ZMK reports battery over the BLE battery service only, and its USB HID
descriptor declares no battery usage, so a wired-only board has nothing to read.
