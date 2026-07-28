# ========================================
# 🔧 ZSH CONFIGURATION
# ========================================

source_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    source "$file"
  fi
}

# Termux opens interactive Zsh as a non-login shell, so .zprofile does not
# initialize an already-installed SDKMAN. Load it here once for Termux only.
if { [ -n "${TERMUX_VERSION:-}" ] || [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ]; } \
  && [ "${_ZPROFILE_SOURCED:-}" != 1 ]; then
  source_if_exists "$ZDOTDIR/env/sdkman.zsh"
fi

# ========================================
# 🧱 RC MODULES
# ========================================
source_if_exists "$ZDOTDIR/rc/options.zsh"
source_if_exists "$ZDOTDIR/rc/aliases.zsh"
source_if_exists "$ZDOTDIR/rc/history.zsh"
source_if_exists "$ZDOTDIR/rc/zinit.zsh"
source_if_exists "$ZDOTDIR/rc/p10k.zsh"
source_if_exists "$ZDOTDIR/rc/completion.zsh"
source_if_exists "$ZDOTDIR/rc/tools.zsh"

# ZLE plugins require an initialized completion system. Load them in the
# foreground instead of Zinit Turbo jobs to keep concurrent terminal startup
# reliable.
if type load_zle_plugins >/dev/null 2>&1; then
  load_zle_plugins
fi
