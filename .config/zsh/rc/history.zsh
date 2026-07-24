# RC: History
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Configures shell history behavior.
#
# RESPONSIBILITIES
#   ✔ HISTFILE location (XDG-compliant)
#   ✔ history size limits
#   ✔ history options (deduplication, timestamps, etc.)
#
# RULE OF THUMB
#   "Does this affect command history storage or behavior?"
#     → YES → belongs here
#
# LOADED FROM
#   .zshrc
# }}

# History directory in the XDG layout.
test -d "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" || mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"

# History file and size.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=10000
SAVEHIST=10000

# Patterns to exclue. Separate with |. *-matching.
HISTORY_IGNORE="poweroff|reboot|halt|shutdown|xlogout"

# History behavior.
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE