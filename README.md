# devconfig
my scripts for dev

## Quick install

**Ubuntu:**
```bash
curl -fsSL https://raw.githubusercontent.com/rek/devconfig/master/install/install.sh | bash
```

**Arch / Omarchy:**
```bash
curl -fsSL https://raw.githubusercontent.com/rek/devconfig/master/install/install-arch.sh | bash
```

Or after cloning:
```bash
mkdir -p ~/dev && git clone https://github.com/rek/devconfig.git ~/dev/devconfig
~/dev/devconfig/install/install.sh         # Ubuntu
~/dev/devconfig/install/install-arch.sh    # Arch / Omarchy
```

The repo is cloned to `~/dev/devconfig` (both the quick-install one-liner and
the script's auto-clone fallback use this location).

The Arch variant backs up any existing dotfiles/configs to `*.bak` before symlinking
(Omarchy ships its own `.zshrc`, hypr config, etc. — you'll want to merge anything
useful from `~/.zshrc.bak` back in).

## Things to do after installing Ubuntu

### Install

```bash
sudo apt-get install aptitude git zsh htop curl alacritty
```

### Manual Install

See [docs/manual-install.md](docs/manual-install.md).

### Dev Config

```bash
mkdir -p ~/dev && git clone https://github.com/rek/devconfig.git ~/dev/devconfig && ~/dev/devconfig/install/install.sh
```

### K8S

```bash
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

### Set default terminal

```bash
sudo update-alternatives --set x-terminal-emulator /usr/bin/alacritty
```

### Misc

```bash
git config --global pager.branch false
```

## Things to do after installing Arch / Omarchy

### Dropdown terminal (CapsLock toggle)

CapsLock toggles a ghostty window that slides down from the top, with tabs at
the bottom (ddterm-style) and no zellij multiplexer.

```bash
~/dev/devconfig/scripts/setup-dropdown-term.sh
```

This installs `keyd` (remaps CapsLock → F13 at evdev), `pyprland` (scratchpad
daemon), and `ghostty`. Configs are already symlinked from this repo:

- `.config/pypr/config.toml` — scratchpad geometry and the launch command.
  Sets `DDTERM=1` so `.zshrc` skips the auto-attach to zellij.
- `.config/ghostty/config` — `gtk-tabs-location = bottom` and
  `gtk-single-instance = false` so per-launch env doesn't leak between windows.
- `.config/hypr/bindings.conf` — binds the F13 keycode (191) to `pypr toggle term`.

### Display setup

```bash
~/dev/devconfig/scripts/display-setup.sh extend          # Philips + Laptop + Glasses
~/dev/devconfig/scripts/display-setup.sh desk            # Philips + Laptop (+ 2nd external)
~/dev/devconfig/scripts/display-setup.sh glasses-only    # Glasses (top) + Laptop (bottom)
~/dev/devconfig/scripts/display-setup.sh status          # Show current layout
```

Applies via `hyprctl keyword monitor=...` AND persists to
`~/.config/hypr/monitors-runtime.conf` (sourced from `hyprland.conf`), so the
layout survives Hyprland config reloads. Auto-detects monitors by name/EDID.

## Parallel Arch / Ubuntu config sets

This repo keeps **both** an Arch/Omarchy/Hyprland version and a Ubuntu/GNOME
version of every desktop-touching script and config:

| Concern | Arch (default) | Ubuntu / GNOME (`.gnome` suffix) |
| --- | --- | --- |
| Dropdown terminal | `scripts/setup-dropdown-term.sh` (ghostty + pyprland) | `scripts/setup-dropdown-term.gnome.sh` (amezin/ddterm patches in `ddterm/`) |
| Display setup | `scripts/display-setup.sh` (hyprctl) | `scripts/display-setup.gnome.sh` + `scripts/xreal-apply-triple.gnome.py` (Mutter D-Bus) |
| Pyprland scratchpad | `.config/pypr/config.toml` | — (ddterm extension handles dropdown on GNOME) |
| Hyprland | `.config/hypr/*` | — |

The default name targets Arch; the `.gnome.<ext>` suffix targets the prior
Ubuntu/GNOME setup. (Note: the top-level installers `install/install.sh` and
`install/install-arch.sh` predate this convention and use an inverted naming — the
dropdown/xreal pattern above is the canonical one going forward.)

## ddterm (GNOME / Ubuntu only)

> Used only on Ubuntu/GNOME. On Arch/Hyprland the dropdown is ghostty
> via pyprland — see *Things to do after installing Arch / Omarchy* above.

Preferred dropdown terminal on Ubuntu Wayland. Install via GNOME Extension
Manager, search `ddterm`. Then apply the patches and Claude hooks:

```bash
~/dev/devconfig/scripts/setup-dropdown-term.gnome.sh
```

### CapsLock as toggle key

CapsLock is mapped to `F13` in `/usr/share/X11/xkb/symbols/pc`:
```
key <CAPS> {[  F13  ]};
```

Reload after changes:
```bash
setxkbmap -layout us
```

In ddterm preferences, set the toggle shortcut to `F13` (press CapsLock when prompted).

### Tab shortcuts

Set via dconf (the GUI dialog can't capture Ctrl+Tab):
```bash
dconf write /com/github/amezin/ddterm/shortcut-next-tab "['<Primary>Tab']"
dconf write /com/github/amezin/ddterm/shortcut-prev-tab "['<Primary><Shift>Tab']"
```

## Guake (X11 / legacy)

> **Deprecated:** prefer ddterm on Ubuntu Wayland, or the ghostty/pyprland
> dropdown on Arch.

Install: `sudo apt install guake`

Settings:
- Main Window: Disable "appear on mouse display," enable "hide on lose focus"
- Shell: Set default interpreter to zsh
- Scrolling: Set scrollback lines to 10000
- Appearance: Select "homebrew" built-in scheme
- Quick open: `code -g %(file_path)s:%(line_number)s`
