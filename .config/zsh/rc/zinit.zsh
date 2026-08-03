# RC: Zinit Plugin Manager
#
# RESPONSIBILITIES
#   - Bootstrap Zinit.
#   - Load Zsh plugins only.
#
# Binary tools are installed by setup scripts, never during shell startup.

ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
	print -u2 -- "zinit not found at $ZINIT_HOME — run the install script"
	return 1
fi
source "$ZINIT_HOME/zinit.zsh"

# Plugin used by rc/tools/fzf-marks.zsh after bindkey is configured.
zinit ice pick"/dev/null" nocompile
zinit light urbainvaes/fzf-marks

# Completion plugins must load before compinit.
zinit ice blockf lucid nocompile
zinit light zsh-users/zsh-completions

# ZLE plugins load after compinit from .zshrc.
load_zle_plugins() {
	zinit ice lucid nocompile atload'!_zsh_autosuggest_start'
	zinit light zsh-users/zsh-autosuggestions

	if [ -f "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/features/fzf-tab.enabled" ]; then
		zinit ice lucid nocompile
		zinit light Aloxaf/fzf-tab
	fi

	zinit ice lucid nocompile
	zinit light hlissner/zsh-autopair

	zinit ice lucid nocompile
	zinit light zdharma-continuum/fast-syntax-highlighting
}
