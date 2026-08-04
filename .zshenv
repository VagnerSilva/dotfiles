export ZDOTDIR="$HOME"
export ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
ZSH_ENV_FILE="$ZSH_CONFIG_DIR/env/xdg-zsh.zsh"

if [ -f "$ZSH_ENV_FILE" ]; then
  . "$ZSH_ENV_FILE"
fi

unset ZSH_ENV_FILE
