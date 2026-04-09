#!/bin/bash
# Fresh Ubuntu developer environment setup
# Usage (one-liner): curl -fsSL https://raw.githubusercontent.com/rek/devconfig/master/bin/install.sh | bash
# Usage (after clone): ./bin/install.sh
set -e

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
header() {
  echo ""
  echo "--- $1"
}

# ---------------------------------------------------------------------------
# 1. apt packages
# ---------------------------------------------------------------------------
header "Installing apt packages..."
sudo apt-get update -q
sudo apt-get install -y aptitude git zsh htop curl alacritty wl-clipboard

# ---------------------------------------------------------------------------
# 2. oh-my-zsh
# ---------------------------------------------------------------------------
header "Installing oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh already installed, skipping."
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Ensure ZSH_CUSTOM is set (oh-my-zsh sets this, but we may need it before sourcing)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ---------------------------------------------------------------------------
# 3. powerlevel10k theme
# ---------------------------------------------------------------------------
header "Installing powerlevel10k theme..."
if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "powerlevel10k already installed, skipping."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ---------------------------------------------------------------------------
# 4. ZSH plugins
# ---------------------------------------------------------------------------
header "Installing ZSH plugins..."

PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

if [ -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
  echo "zsh-autosuggestions already installed, skipping."
else
  git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DIR/zsh-autosuggestions"
fi

if [ -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
  echo "zsh-syntax-highlighting already installed, skipping."
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGINS_DIR/zsh-syntax-highlighting"
fi

if [ -d "$PLUGINS_DIR/zsh-completions" ]; then
  echo "zsh-completions already installed, skipping."
else
  git clone https://github.com/zsh-users/zsh-completions "$PLUGINS_DIR/zsh-completions"
fi

# ---------------------------------------------------------------------------
# 5. Clone devconfig repo (if not already running from within it)
# ---------------------------------------------------------------------------
header "Setting up devconfig repo..."

# Determine if we're already inside the repo by checking for a known marker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT=""

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../dotfiles/.zshrc" ]; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  echo "Running from within repo at $REPO_ROOT, skipping clone."
else
  if [ -d "$HOME/devconfig" ]; then
    echo "devconfig already cloned at ~/devconfig, skipping."
  else
    git clone https://github.com/rek/devconfig.git "$HOME/devconfig"
  fi
  REPO_ROOT="$HOME/devconfig"
fi

# ---------------------------------------------------------------------------
# 6. Symlink dotfiles
# ---------------------------------------------------------------------------
header "Symlinking dotfiles to ~/ ..."
for f in "$REPO_ROOT"/dotfiles/.*; do
  [ "$(basename "$f")" = "." ] || [ "$(basename "$f")" = ".." ] && continue
  ln -sf "$f" "$HOME/$(basename "$f")"
done

# ---------------------------------------------------------------------------
# 7. Symlink .config entries
# ---------------------------------------------------------------------------
header "Symlinking .config to ~/ ..."
mkdir -p "$HOME/.config"
for d in "$REPO_ROOT"/.config/*/; do
  ln -sf "$d" "$HOME/.config/$(basename "$d")"
done

# ---------------------------------------------------------------------------
# 8. Install zellij
# ---------------------------------------------------------------------------
header "Installing zellij..."
if command -v zellij &>/dev/null || [ -f "$HOME/.local/bin/zellij" ]; then
  echo "zellij already installed, skipping."
else
  bash "$REPO_ROOT/bin/install-zellij"
fi

# ---------------------------------------------------------------------------
# 9. Set alacritty as default terminal
# ---------------------------------------------------------------------------
header "Setting alacritty as default terminal..."
sudo update-alternatives --set x-terminal-emulator /usr/bin/alacritty

# ---------------------------------------------------------------------------
# 10. kubectx / kubens
# ---------------------------------------------------------------------------
header "Installing kubectx/kubens..."
if [ -d "/opt/kubectx" ]; then
  echo "kubectx already installed, skipping."
else
  sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
  sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
  sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
fi

# ---------------------------------------------------------------------------
# 11. git config
# ---------------------------------------------------------------------------
header "Configuring git..."
git config --global pager.branch false

# ---------------------------------------------------------------------------
# 12. Set zsh as default shell
# ---------------------------------------------------------------------------
header "Setting zsh as default shell..."
if [ "$SHELL" = "$(which zsh)" ]; then
  echo "zsh is already the default shell, skipping."
else
  chsh -s "$(which zsh)"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
echo " Setup complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  - Log out and log back in (or run 'exec zsh') for zsh to take effect."
echo "  - If you changed your default shell, a full logout/login is required."
echo ""
