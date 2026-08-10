# RC: Aliases
# Suppress alias expansion:: $ \aliasname || 'aliasname'
# Print alias definition: alias <aliasname>
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Defines a comprehensive set of **interactive aliases and command wrappers**
#   to improve CLI ergonomics, defaults, and workflows across environments.
#
#   This file centralizes all alias logic, including OS-specific behavior,
#   tool enhancements, and productivity shortcuts.
#
# RESPONSIBILITIES
#   ✔ Desktop/OS-specific command behavior
#     - open, logout, screensaver, trash handling
#     - Conditional logic via $DESKTYPE and platform checks
#
#   ✔ CLI UX improvements
#     - Enable colors (ls, grep, gcc diagnostics)
#     - Improve defaults for common tools
#
#   ✔ Tool substitution and enhancement
#     - Prefer modern tools if available (eza for ls, lsd, colordiff, cdu)
#     - Normalize behavior across systems (BSD vs GNU)
#
#   ✔ Program-specific aliases
#     - vim/nvim behavior
#     - libreoffice commands
#     - gpg, pdflatex, octave, etc.
#
#   ✔ Workflow and productivity shortcuts
#     - File/system utilities (ll, dusch, mkdirtoday, etc.)
#     - Git helpers, systemctl shortcuts, process helpers
#     - fzf-marks integration and bookmark helpers
#
#   ✔ XDG compatibility wrappers
#     - Force tools to respect XDG config locations
#
#   ✔ SSH and system helpers
#     - ssh-agent helpers (keyon/off/list)
#     - sudo command wrappers
#
#   ✘ DO NOT put here:
#     - Environment variables (→ env/*)
#     - PATH modifications (→ env/programs.zsh)
#     - Tool initialization or sourcing (→ rc/tools.zsh)
#     - Large or slow logic unrelated to command usage
#
# WHY
#   This file:
#     - standardizes command behavior across machines
#     - reduces friction in daily terminal usage
#     - adapts dynamically to available tools and OS differences
#
#   It acts as a **UX layer** on top of the raw shell environment.
#
# STARTUP CONTEXT
#   Loaded during:
#     → .zshrc (interactive shells only)
#
#   So it affects:
#     - terminal sessions
#     - NOT scripts or non-interactive shells
#
# RULE OF THUMB
#   "Does this change how I type or use commands interactively?"
#     → YES → put it here
#
#   "Does this configure environment or initialize a tool?"
#     → NO → belongs in env/* or rc/tools.zsh
# }}

alias gcm='git commit -m'
alias gp='git push'
alias gpf='git push --force'
alias gsu='git stash -u'
alias gsa='git stash apply'
alias gpl='git pull'

c() {
	clear
}
