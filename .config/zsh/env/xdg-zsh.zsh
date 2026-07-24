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

# ZSH configuration directory
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

# ZSH history
export HISTFILE="$ZDOTDIR/.zhistory"

# Create necessary cache directories
mkdir -p "$XDG_CACHE_HOME/zsh"
