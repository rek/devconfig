#!/bin/bash
# Arch / Omarchy developer environment setup
# Usage: ~/dev/devconfig/install/install-arch.sh
#
# Differences vs install.sh (Ubuntu):
#   - pacman / AUR helper instead of apt
#   - No alacritty default-terminal step (Hyprland handles via hypr config)
#   - Backs up existing dotfiles/config dirs before symlinking (Omarchy ships its own)
#   - kubectx via AUR
set -e
shopt -s nullglob

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
header() {
  echo ""
  echo "--- $1"
}

# ---------------------------------------------------------------------------
# 0. Sanity check — must be on Arch
# ---------------------------------------------------------------------------
if ! command -v pacman >/dev/null; then
  echo "pacman not found — this is the Arch variant. Use install/install.sh on Ubuntu."
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. AUR helper detection
# ---------------------------------------------------------------------------
if command -v paru >/dev/null; then
  AUR=paru
elif command -v yay >/dev/null; then
  AUR=yay
else
  AUR=""
  echo "No AUR helper (paru/yay) found — AUR packages will be skipped."
  echo "Install one with: sudo pacman -S --needed base-devel git && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
fi

# ---------------------------------------------------------------------------
# 2. pacman packages
# ---------------------------------------------------------------------------
header "Installing pacman packages..."
sudo pacman -S --needed --noconfirm git zsh curl htop btop alacritty wl-clipboard

# ---------------------------------------------------------------------------
# 3. Devconfig repo location (needed before symlinking dotfiles below)
# ---------------------------------------------------------------------------
header "Setting up devconfig repo..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT=""

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../dotfiles/.zshrc" ]; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  echo "Running from within repo at $REPO_ROOT, skipping clone."
else
  REPO_ROOT="$HOME/dev/devconfig"
  if [ -d "$REPO_ROOT" ]; then
    echo "devconfig already cloned at $REPO_ROOT, skipping."
  else
    mkdir -p "$HOME/dev"
    git clone https://github.com/rek/devconfig.git "$REPO_ROOT"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Symlink dotfiles BEFORE oh-my-zsh so Omarchy's originals get cleanly
#    backed up to *.bak (otherwise oh-my-zsh would rename them to
#    .zshrc.pre-oh-my-zsh and our .bak would be the oh-my-zsh template)
# ---------------------------------------------------------------------------
header "Symlinking dotfiles to ~/ ..."
for f in "$REPO_ROOT"/dotfiles/.*; do
  base="$(basename "$f")"
  [ "$base" = "." ] || [ "$base" = ".." ] && continue
  target="$HOME/$base"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Backing up existing $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi
  ln -sfn "$f" "$target"
done

# ---------------------------------------------------------------------------
# 5. oh-my-zsh — use --keep-zshrc so our symlinked .zshrc isn't replaced
# ---------------------------------------------------------------------------
header "Installing oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh already installed, skipping."
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ---------------------------------------------------------------------------
# 6. powerlevel10k theme
# ---------------------------------------------------------------------------
header "Installing powerlevel10k theme..."
if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "powerlevel10k already installed, skipping."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ---------------------------------------------------------------------------
# 7. ZSH plugins
# ---------------------------------------------------------------------------
header "Installing ZSH plugins..."
PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting zsh-users/zsh-completions; do
  name="$(basename "$repo")"
  if [ -d "$PLUGINS_DIR/$name" ]; then
    echo "$name already installed, skipping."
  else
    git clone "https://github.com/$repo" "$PLUGINS_DIR/$name"
  fi
done

# ---------------------------------------------------------------------------
# 8. Symlink .config entries — same backup logic
# ---------------------------------------------------------------------------
header "Symlinking .config to ~/ ..."
mkdir -p "$HOME/.config"
for d in "$REPO_ROOT"/.config/*/; do
  target="$HOME/.config/$(basename "$d")"
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    echo "Backing up existing $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi
  ln -sfn "$d" "$target"
done

# ---------------------------------------------------------------------------
# 9. Symlink global commands from bin/ into ~/.local/bin (must be on PATH)
# ---------------------------------------------------------------------------
header "Symlinking bin/ commands to ~/.local/bin ..."
mkdir -p "$HOME/.local/bin"
for f in "$REPO_ROOT"/bin/*; do
  [ -f "$f" ] || continue
  target="$HOME/.local/bin/$(basename "$f")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Backing up existing $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi
  ln -sfn "$f" "$target"
done

# ---------------------------------------------------------------------------
# 10. Install zellij (distro-agnostic — downloads musl binary)
# ---------------------------------------------------------------------------
header "Installing zellij..."
if command -v zellij &>/dev/null || [ -f "$HOME/.local/bin/zellij" ]; then
  echo "zellij already installed, skipping."
else
  bash "$REPO_ROOT/install/install-zellij"
fi

# ---------------------------------------------------------------------------
# 11. kubectx / kubens via AUR
# ---------------------------------------------------------------------------
header "Installing kubectx/kubens..."
if command -v kubectx >/dev/null; then
  echo "kubectx already installed, skipping."
elif [ -n "$AUR" ]; then
  $AUR -S --needed --noconfirm kubectx
else
  echo "Skipping kubectx — install paru or yay first, then: <aur-helper> -S kubectx"
fi

# ---------------------------------------------------------------------------
# 12. git config
# ---------------------------------------------------------------------------
header "Configuring git..."
git config --global pager.branch false

# ---------------------------------------------------------------------------
# 13. scm_breeze (numbered shortcuts for `gs` / git staging)
# ---------------------------------------------------------------------------
header "Installing scm_breeze..."
if [ -d "$HOME/.scm_breeze" ]; then
  echo "scm_breeze already installed, skipping."
else
  git clone https://github.com/scmbreeze/scm_breeze.git "$HOME/.scm_breeze"
  "$HOME/.scm_breeze/install.sh"
fi

# ---------------------------------------------------------------------------
# 14. Set zsh as default shell
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
echo "Notes:"
echo "  - Omarchy's original dotfiles/configs were backed up as *.bak"
echo "  - Review .bak files and merge anything Omarchy-specific you want back"
echo "    (especially ~/.zshrc.bak — Omarchy may set PATH, aliases, prompt hooks)"
echo "  - Log out / log back in (or 'exec zsh') for zsh to take effect"
echo ""
