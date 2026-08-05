# Environment: Paths
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Defines and constructs the system PATH.
#
# RESPONSIBILITIES
#   ✔ Add system and user binary directories
#   ✔ Initialize Homebrew environment
#   ✔ Ensure PATH ordering and deduplication
#   ✔ Ensure needed directories exist
#
# IMPORTANT
#   PATH must be constructed carefully:
#     - order matters
#     - avoid duplicates (typeset -U path)
#
# RULE OF THUMB
#   "Does this change where executables are found?"
#     → YES → belongs here
#
# LOADED FROM
#   .zprofile
# }}

# Remove duplicates in path while keeping the first occurrence.
typeset -U path

# Remove duplicates in fpath while keeping the first occurrence.
typeset -U fpath

# Ensure directories used by Zsh and its tools exist without depending on PATH.
if [ -x "${PREFIX:-}/bin/mkdir" ]; then
  _zsh_mkdir="${PREFIX}/bin/mkdir"
elif [ -x /bin/mkdir ]; then
  _zsh_mkdir=/bin/mkdir
elif [ -x /usr/bin/mkdir ]; then
  _zsh_mkdir=/usr/bin/mkdir
else
  return 1
fi
"$_zsh_mkdir" -p \
  "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/functions" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/completions" \
  "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
unset _zsh_mkdir

# fpath for custom functions and completions.
fpath=("${XDG_CONFIG_HOME:-$HOME/.config}/zsh/functions" $fpath)
fpath=("${XDG_CONFIG_HOME:-$HOME/.config}/zsh/completions" $fpath)

# PATH is already properly set and exported by this point
