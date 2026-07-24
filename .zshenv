ZSH_ENV_FILE="$HOME/.config/zsh/env/xdg-zsh.zsh"

if [ -f "$ZSH_ENV_FILE" ]; then
  . "$ZSH_ENV_FILE"
fi

ZSH_STARTUP_DEBUG_FILE="${ZDOTDIR:-$HOME/.config/zsh}/env/startup-debug.zsh"

if [ -f "$ZSH_STARTUP_DEBUG_FILE" ]; then
  . "$ZSH_STARTUP_DEBUG_FILE"
fi

unset ZSH_ENV_FILE ZSH_STARTUP_DEBUG_FILE
