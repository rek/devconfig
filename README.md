# devconfig
my scripts for dev

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/rek/devconfig/master/bin/install.sh | bash
```

Or after cloning:
```bash
./bin/install.sh
```

## Things to do after installing Ubuntu

### Install

```bash
sudo apt-get install aptitude git zsh htop curl alacritty
```

### Manual Install

See [docs/manual-install.md](docs/manual-install.md).

### Dev Config

```bash
git clone https://github.com/rek/devconfig.git ~/devconfig && ~/devconfig/bin/install.sh
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

## ddterm (Wayland dropdown terminal)

Preferred dropdown terminal on Wayland.

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

## Guake (X11 / legacy)

> **Deprecated:** prefer ddterm on Wayland.

Install: `sudo apt install guake`

Settings:
- Main Window: Disable "appear on mouse display," enable "hide on lose focus"
- Shell: Set default interpreter to zsh
- Scrolling: Set scrollback lines to 10000
- Appearance: Select "homebrew" built-in scheme
- Quick open: `code -g %(file_path)s:%(line_number)s`
