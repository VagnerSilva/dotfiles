#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_ZSH="$SCRIPT_DIR/setup-zsh.sh"
SETUP_TOOLS="$SCRIPT_DIR/setup/tools.sh"
SETUP_ZINIT="$SCRIPT_DIR/setup-zinit.sh"
SETUP_NERD_FONT="$SCRIPT_DIR/setup-nerd-font.sh"

log() { printf '[INFO] %s\n' "$1"; }
error() { printf '[ERROR] %s\n' "$1" >&2; }
print_title() { printf '\n### %s ###\n' "$1"; }
print_step() { printf '%s\n' "$1"; }

require_file() {
	local file="$1"
	[ -f "$file" ] || { error "Required file not found: $file"; return 1; }
}

run_step() {
	local title="$1" script="$2"
	print_step "$title"
	bash "$script"
}

main() {
	print_title "Dotfiles installation"
	log "This installer will guide you through zsh, tools, zinit and Nerd Font setup."

	require_file "$SETUP_ZSH"
	require_file "$SETUP_TOOLS"
	require_file "$SETUP_ZINIT"
	require_file "$SETUP_NERD_FONT"

	run_step "Step 1/4 - zsh setup" "$SETUP_ZSH"
	run_step "Step 2/4 - tools setup" "$SETUP_TOOLS"
	run_step "Step 3/4 - zinit setup" "$SETUP_ZINIT"
	run_step "Step 4/4 - Nerd Font setup" "$SETUP_NERD_FONT"

	printf '\nDone.\n'
	printf 'Open a new zsh session to apply all changes.\n'
}

main "$@"
