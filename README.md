# devconfig
my scripts for dev

## How to use this stuff:
```
cp -r .config ~
cp dotfiles/* ~/
ln -s bin/* /usr/local/bin

# Install zellij (terminal multiplexer, replaces byobu)
./bin/install-zellij
```

## Other things to do

https://gist.github.com/rek/296c6544e08cc8198f4e04ce68e8d7fc

## ddterm (Wayland dropdown terminal)

Install via GNOME Extension Manager, search `ddterm`.

## Guake (X11 dropdown terminal)

Install: `sudo apt install guake`

Zellij auto-start is skipped automatically in Guake (detected via parent process).
No extra config needed — just open Guake and get a plain shell.

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
