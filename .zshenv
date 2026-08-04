if command -v zsh >/dev/null 2>&1; then
  export SHELL="$(command -v zsh)"
fi

ZSH_ENV_FILE="$HOME/.config/zsh/env/xdg-zsh.zsh"

if [ -f "$ZSH_ENV_FILE" ]; then
  . "$ZSH_ENV_FILE"
fi

unset ZSH_ENV_FILE
