# devconfig
my scripts for dev

## Things to do after installing Ubuntu

### Install

```bash
sudo apt-get install aptitude git zsh htop curl
```

### Manual Install

- [Chrome](https://www.google.com/chrome/)
- [VSCode](https://code.visualstudio.com/)
- [GH CLI](https://cli.github.com/)
- [NVM](https://github.com/nvm-sh/nvm)

### ZSH

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
```

Plugins:
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
```

Fonts: https://github.com/romkatv/powerlevel10k#manual-font-installation

### Dev Config

```bash
git clone https://github.com/rek/devconfig.git && cd devconfig
cp -r .config ~
cp dotfiles/* ~/
ln -s bin/* /usr/local/bin

# Install zellij (terminal multiplexer)
./bin/install-zellij
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

Install via GNOME Extension Manager, search `ddterm`.

## Guake (X11 dropdown terminal)

Install: `sudo apt install guake`

Zellij auto-start is skipped automatically in Guake (detected via parent process).
No extra config needed — just open Guake and get a plain shell.

Settings:
- Main Window: Disable "appear on mouse display," enable "hide on lose focus"
- Shell: Set default interpreter to zsh
- Scrolling: Set scrollback lines to 10000
- Appearance: Select "homebrew" built-in scheme
- Quick open: `code -g %(file_path)s:%(line_number)s`

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
