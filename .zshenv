if command -v zsh >/dev/null 2>&1; then
  export SHELL="$(command -v zsh)"
fi

export ZDOTDIR="$HOME"
export ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}"
unset _ZPROFILE_SOURCED

case "${OSTYPE:-}" in
  darwin*) export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" ;;
  *) export PATH="${PREFIX:+$PREFIX/bin:}/usr/local/bin:/usr/bin:/bin:$PATH" ;;
esac

ZSH_ENV_FILE="$ZSH_CONFIG_DIR/env/xdg-zsh.zsh"

if [ -f "$ZSH_ENV_FILE" ]; then
  . "$ZSH_ENV_FILE"
fi

unset ZSH_ENV_FILE
