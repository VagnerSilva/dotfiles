# ========================================
# ⚡ POWERLEVEL10K INSTANT PROMPT
# ========================================
# Must be at the top, before any other code
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ========================================
# 🔧 ZSH CONFIGURATION
# ========================================

source_if_exists() {
  local file="$1"
  [[ -f "$file" ]] && source "$file"
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

# ========================================
# 🎉 FINAL MESSAGES (after full load)
# ========================================
# Only if running in an interactive terminal and instant prompt has finished
if [[ -t 1 ]] && { [[ -z "$P10K_INSTANT_PROMPT_ACTIVE" ]] || [[ "$P10K_INSTANT_PROMPT_ACTIVE" != "1" ]]; }; then
  echo
  echo -e "\e[32m✅ Zsh loaded successfully!\e[0m"
  echo -e "\e[34m💡 Tip:\e[0m Use \e[1m'p10k configure'\e[0m to customize the theme"
  echo -e "\e[33m🚀 Ready to code!\e[0m"
  echo
fi

export PATH=$PATH:/usr/local/go/bin
export GOPATH=/home/vagners/homebrew/go
export PATH=$PATH:$GOPATH/bin

source_if_exists "$HOME/.local/bin/env"
