# Environment: XDG Base Directory Specification for ZSH
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Implements XDG Base Directory Specification for ZSH and related tools.
#   https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
#
# RESPONSIBILITIES
#   ✔ Set XDG_* variables if not already set
#   ✔ Redirect ZSH dotfiles to ~/.config/zsh
#   ✔ Redirect cache to ~/.cache
#   ✔ Redirect data to ~/.local/share
#
# LOADED FROM
#   .zshenv (all shells)
# }}

# XDG Base Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ZSH startup files stay in $HOME; modules use a separate config directory.
export ZDOTDIR="${ZDOTDIR:-$HOME}"
export ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$XDG_CONFIG_HOME/zsh}"

# Create the cache directory without depending on PATH during startup.
if [ -x "${PREFIX:-}/bin/mkdir" ]; then
  "${PREFIX}/bin/mkdir" -p "$XDG_CACHE_HOME/zsh"
elif [ -x /bin/mkdir ]; then
  /bin/mkdir -p "$XDG_CACHE_HOME/zsh"
elif [ -x /usr/bin/mkdir ]; then
  /usr/bin/mkdir -p "$XDG_CACHE_HOME/zsh"
fi
