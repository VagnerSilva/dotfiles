# Environment: Programs
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Defines environment for language runtimes and CLI tools.
#
# RESPONSIBILITIES
#   ✔ Language/tool environment variables:
#     - Ruby, Python, Perl configs
#     - build/runtime flags used by installed toolchains
#
#   ✔ Global tool behavior:
#     - LESS
#     - EDITOR
#     - GPG_TTY
#
#   ✔ PATH extensions required by tools
#
# IMPORTANT
#   Everything here should be:
#     - needed by scripts
#     - relevant outside interactive shells
#
# RULE OF THUMB
#   "Would a script need this environment?"
#     → YES → belongs here
#     → NO  → belongs in rc/
#
# LOADED FROM
#   .zprofile
# }}



# Node {{
if [ -d "$XDG_DATA_HOME/npm/bin" ]; then
	export PATH="$XDG_DATA_HOME/npm/bin:$PATH"
fi
# }}

