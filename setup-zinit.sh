#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/setup/common.sh"
ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
ZINIT_REPO_URL="https://github.com/zdharma-continuum/zinit.git"
ZINIT_ENTRYPOINT="$ZINIT_HOME/zinit.zsh"
FZF_TAB_FLAG_FILE="$XDG_STATE_HOME/zsh/features/fzf-tab.enabled"
require_zinit_dependencies() { require_command git; require_command zsh; }
clone_or_update_zinit() {
	mkdir -p "$(dirname "$ZINIT_HOME")"
	if [ -d "$ZINIT_HOME/.git" ]; then git -C "$ZINIT_HOME" pull --ff-only
	elif [ -e "$ZINIT_HOME" ]; then error "$ZINIT_HOME exists but is not a Git repository."; return 1
	else git clone "$ZINIT_REPO_URL" "$ZINIT_HOME"; fi
}
configure_optional_fzf_tab() {
	[ -f "$FZF_TAB_FLAG_FILE" ] && { log "fzf-tab is enabled."; return 0; }
	if confirm_step "Enable fzf-tab plugin?"; then mkdir -p "$(dirname "$FZF_TAB_FLAG_FILE")"; : > "$FZF_TAB_FLAG_FILE"; fi
}
verify_installation() { [ -f "$ZINIT_ENTRYPOINT" ] || { error "Zinit entrypoint not found: $ZINIT_ENTRYPOINT"; return 1; }; log "Zinit ready at $ZINIT_HOME."; }
main() { printf '\n### Zinit setup ###\n'; require_zinit_dependencies; clone_or_update_zinit; verify_installation; configure_optional_fzf_tab; }
main "$@"
