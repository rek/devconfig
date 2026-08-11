# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("/home/adam/.oh-my-zsh/custom/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

# Auto-start zellij (replaced byobu)
# Only auto-attach when opening a fresh terminal — skip if zellij isn't installed, if already
# inside a multiplexer (zellij/tmux/screen/byobu), or in VS Code, Guake, ddterm, embedded terms.
# If another terminal is already attached to a zellij session, create a fresh per-terminal session
# instead of piling onto `default` (so each monitor/window gets its own state).
# ddterm detection: an env var set only on the ghostty -e launch command (DDTERM=1)
# doesn't survive new tabs opened natively inside that window (ghostty spawns those
# tabs' shells fresh, without re-running -e). Ask Hyprland for the current window's
# class instead — it's true for every tab of the dropdown window, not just the first.
_parent_proc=$(ps -p $PPID -o comm= 2>/dev/null)
_win_class=""
if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
  _win_class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null)
fi
if [[ -x ~/.local/bin/zellij && -z "$TMUX" && -z "$STY" && -z "$BYOBU_BACKEND" && -z "$ZELLIJ" && -z "$ZELLIJ_SESSION_NAME" && "$TERM_PROGRAM" != "vscode" && "$TERM_PROGRAM" != "guake" && -z "$INSIDE_EMACS" && -z "$VIMRUNTIME" && -z "$GUAKE" && "$_parent_proc" != "guake" && -z "$DDTERM" && "$_win_class" != "dropdown.term" ]]; then
  if pgrep -f 'zellij attach' >/dev/null 2>&1; then
    exec ~/.local/bin/zellij attach --create "term-$$"
  else
    exec ~/.local/bin/zellij attach --create default
  fi
fi
unset _parent_proc _win_class

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/adam/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="../custom/powerlevel10k/powerlevel10k"
# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git kubectl oc zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source $HOME/.aliases

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# source ~/powerlevel10k/powerlevel10k.zsh-theme
source $ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir rbenv status)
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(vcs root_indicator background_jobs history time)

COGNITE_API_KEY=123

export GITHUB_USERNAME=rek

# bun completions
[ -s "/home/adam/.bun/_bun" ] && source "/home/adam/.bun/_bun"

# bun
export BUN_INSTALL="/home/adam/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export DENO_INSTALL="/home/adam/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# linux brew
export PATH="$HOME/.linuxbrew/bin:$PATH"
export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Openshift
export PATH="/home/adam/.crc/bin/oc:$PATH"
export PATH="$HOME/.crc/bin/oc:$PATH"

# Java — Arch's archlinux-java default (JDK 21), Debian/Ubuntu's update-alternatives default
for _java_home in /usr/lib/jvm/default /usr/lib/jvm/default-java; do
  [ -d "$_java_home" ] && export JAVA_HOME="$_java_home" && break
done
unset _java_home

# Android SDK (Arch: AUR /opt/android-sdk; Ubuntu: Studio's ~/Android/Sdk)
for _android_home in /opt/android-sdk "$HOME/Android/Sdk"; do
  if [ -d "$_android_home" ]; then
    export ANDROID_HOME="$_android_home"
    export ANDROID_SDK_ROOT=$ANDROID_HOME
    export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/29.0.14206865
    # avdmanager stores AVDs in ~/.config/.android/avd (XDG), but the emulator defaults
    # to ~/.android/avd. Point both at the same place so `emulator -list-avds` (and Expo) find them.
    export ANDROID_AVD_HOME=$HOME/.config/.android/avd
    # emulator must come BEFORE /opt/android-sdk/tools (added by /etc/profile.d/android-sdk.sh
    # on Arch), which contains a broken legacy emulator binary. Prepend so the real one wins.
    export PATH=$ANDROID_HOME/emulator:$PATH
    export PATH=$PATH:$ANDROID_HOME/platform-tools
    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
    break
  fi
done
unset _android_home

export PATH=$PATH:/home/adam/bin

# Moon
# export PATH="/home/adam/.moon/bin:$PATH"

# Proto
export PROTO_HOME="$HOME/.proto"
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
#export PATH="$HOME/.moon/bin:$PATH"

# freetype
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/adam/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/adam/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/adam/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/adam/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# scm_breeze wraps `git` in a shell function whose helpers don't survive
# Claude Code's shell snapshot (git switch/checkout/branch break). Skip it there.
[ -z "$CLAUDECODE" ] && [ -s "/home/adam/.scm_breeze/scm_breeze.sh" ] && source "/home/adam/.scm_breeze/scm_breeze.sh"

export PATH=$PATH:/usr/local/go/bin
export LD_LIBRARY_PATH=/usr/lib32/nvidia:/usr/lib/nvidia:$LD_LIBRARY_PATH

# add fuzzy finder (Arch ships /usr/share/fzf, Debian/Ubuntu /usr/share/doc/fzf/examples)
for _fzf_dir in /usr/share/fzf /usr/share/doc/fzf/examples; do
  if [ -d "$_fzf_dir" ]; then
    [ -f "$_fzf_dir/key-bindings.zsh" ] && source "$_fzf_dir/key-bindings.zsh"
    [ -f "$_fzf_dir/completion.zsh" ] && source "$_fzf_dir/completion.zsh"
    break
  fi
done
unset _fzf_dir

# for beads ai coding tool
export PATH="$PATH:/home/adam/go/bin"


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/adam/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/home/adam/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/adam/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/adam/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

# add Pulumi to the PATH
export PATH=$PATH:/home/adam/.pulumi/bin

# VS Code shell integration
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# peon-ping quick controls
alias peon="bash /home/adam/.claude/hooks/peon-ping/peon.sh"
[ -f /home/adam/.claude/hooks/peon-ping/completions.bash ] && source /home/adam/.claude/hooks/peon-ping/completions.bash

# Run Claude Code against the local Ollama server (RTX 5090).
# Usage: claude-local [claude args...]   e.g. claude-local -p "explain this repo"
# Override model: CLAUDE_LOCAL_MODEL=qwen3.5 claude-local
claude-local() {
  local model="${CLAUDE_LOCAL_MODEL:-devstral}"
  if ! curl -sf -m 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "ollama not responding — starting service..."
    sudo systemctl start ollama && sleep 2
  fi
  ANTHROPIC_AUTH_TOKEN=ollama \
  ANTHROPIC_API_KEY="" \
  ANTHROPIC_BASE_URL=http://localhost:11434 \
  claude --model "$model" "$@"
}

