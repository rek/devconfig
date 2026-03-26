# devconfig
my scripts for dev

## How to use this stuff:
```
cp -r .config .byobu ~
cp dotfiles/* ~/
ln -s bin/* /usr/local/bin
```

## Other things to do

https://gist.github.com/rek/296c6544e08cc8198f4e04ce68e8d7fc

## ddterm (Wayland dropdown terminal)

Install via GNOME Extension Manager, search `ddterm`.

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
