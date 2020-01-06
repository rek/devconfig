source $HOME/.aliases

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir rbenv status)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(vcs root_indicator background_jobs history time)
