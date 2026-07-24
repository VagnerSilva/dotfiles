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

# ========================================
# 🧱 RC MODULES
# ========================================
source_if_exists "$ZDOTDIR/rc/options.zsh"
source_if_exists "$ZDOTDIR/rc/aliases.zsh"
source_if_exists "$ZDOTDIR/rc/history.zsh"
source_if_exists "$ZDOTDIR/rc/p10k.zsh"
source_if_exists "$ZDOTDIR/rc/zinit.zsh"
source_if_exists "$ZDOTDIR/rc/tools.zsh"
source_if_exists "$ZDOTDIR/rc/completion.zsh"

# Load p10k configuration
if [ -f ~/.p10k.zsh ]; then
  source ~/.p10k.zsh
fi
