if command -v zsh >/dev/null 2>&1; then
  export SHELL="$(command -v zsh)"
fi

export ZDOTDIR="${ZDOTDIR:-$HOME}"
export ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}"

ZSH_ENV_FILE="$ZSH_CONFIG_DIR/env/xdg-zsh.zsh"

if [ -f "$ZSH_ENV_FILE" ]; then
  . "$ZSH_ENV_FILE"
fi

unset ZSH_ENV_FILE
