# Environment: PowerLevel10k Theme
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Initializes environment variables for PowerLevel10k theme.
#
# RESPONSIBILITIES
#   ✔ Set up cache directory for P10k instant prompt
#
# LOADED FROM
#   .zprofile (login shells)
# }}

# PowerLevel10k instant prompt cache
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
