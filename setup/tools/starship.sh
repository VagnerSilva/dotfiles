#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
STARSHIP_CONFIG_FILE="$XDG_CONFIG_HOME/starship.toml"
STARSHIP_PRESET_FILE="$XDG_STATE_HOME/zsh/starship-preset"
STARSHIP_BIN="$HOME/.local/bin/starship"
if ! is_command_available starship; then
	if ! confirm_step "Install Starship?"; then warn "Starship installation skipped."; exit 0; fi
	if is_termux; then install_packages pkg starship; else
		installer="$(mktemp)"; trap 'rm -f "$installer"' EXIT
		curl -fsSL https://starship.rs/install.sh -o "$installer"
		mkdir -p "$(dirname "$STARSHIP_BIN")"; sh "$installer" -y -b "$HOME/.local/bin"
	fi
fi
if [ -s "$STARSHIP_PRESET_FILE" ] && is_command_available starship; then
	read -r preset < "$STARSHIP_PRESET_FILE"; mkdir -p "$(dirname "$STARSHIP_CONFIG_FILE")"
	starship preset "$preset" --output "$STARSHIP_CONFIG_FILE" --force; rm -f -- "$STARSHIP_PRESET_FILE"
fi
log "Starship setup complete."
