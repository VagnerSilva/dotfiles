# Environment: XDG
# Make programs respect XDG.
# Most $XDG_* vars are set in ~/.zshenv
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Centralizes XDG Base Directory configuration.
#
# RESPONSIBILITIES
#   ✔ Define XDG-related environment variables for programs
#   ✔ Redirect tool configs away from $HOME into XDG paths
#
# EXAMPLES
#   - INPUTRC
#   - GNUPGHOME
#   - DOCKER_CONFIG
#
# RULE OF THUMB
#   "Does this tell a program WHERE to store its files?"
#     → YES → belongs here
#
# LOADED FROM
#   .zprofile (login shell, environment setup phase)
# }}

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-$HOME/.local/run}"  # Need to be set for yarn(1).

if [ "${CODESPACES:-false}" = true ] || [ "${ZDOTDIR:-$HOME}" = "$HOME" ]; then
  # Force zsh startup files to live in the XDG path when ZDOTDIR is unset or points to $HOME.
  export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
else
  export ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME}/zsh}"
fi

# Minimal PATH so scripts work.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$HOME/bin"