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
source_if_exists "$ZSH_CONFIG_DIR/rc/options.zsh"
source_if_exists "$ZSH_CONFIG_DIR/rc/aliases.zsh"
source_if_exists "$ZSH_CONFIG_DIR/rc/history.zsh"
source_if_exists "$ZSH_CONFIG_DIR/rc/zinit.zsh"
source_if_exists "$ZSH_CONFIG_DIR/rc/p10k.zsh"
source_if_exists "$ZSH_CONFIG_DIR/rc/completion.zsh"
source_if_exists "$ZSH_CONFIG_DIR/rc/tools.zsh"

# ZLE plugins require an initialized completion system. Load them in the
# foreground instead of Zinit Turbo jobs to keep concurrent terminal startup
# reliable.
if type load_zle_plugins >/dev/null 2>&1; then
  load_zle_plugins
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/vagners/.sdkman"
[[ -s "/home/vagners/.sdkman/bin/sdkman-init.sh" ]] && source "/home/vagners/.sdkman/bin/sdkman-init.sh"
