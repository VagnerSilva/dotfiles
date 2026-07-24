# POWERLEVEL10K INSTANT PROMPT
if [ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh" ]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
fi

# ========================================
# 🔧 ZSH CONFIGURATION
# ========================================

source_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    source "$file"
  fi
}

# A terminal spawned by an existing Zsh inherits ZDOTDIR and skips ~/.zshenv.
# Load the optional recorder here as well so every interactive terminal is
# covered, not only login shells.
source_if_exists "$ZDOTDIR/env/startup-debug.zsh"

# ========================================
# 🧱 RC MODULES
# ========================================
source_if_exists "$ZDOTDIR/rc/options.zsh"
source_if_exists "$ZDOTDIR/rc/aliases.zsh"
source_if_exists "$ZDOTDIR/rc/history.zsh"
source_if_exists "$ZDOTDIR/rc/p10k.zsh"
source_if_exists "$ZDOTDIR/rc/zinit.zsh"
source_if_exists "$ZDOTDIR/rc/completion.zsh"
source_if_exists "$ZDOTDIR/rc/tools.zsh"

# ZLE plugins require an initialized completion system. Load them in the
# foreground instead of Zinit Turbo jobs to keep concurrent terminal startup
# reliable.
if type load_zle_plugins >/dev/null 2>&1; then
  load_zle_plugins
fi

# Load p10k configuration
if [ -f ~/.p10k.zsh ]; then
  source ~/.p10k.zsh
fi
