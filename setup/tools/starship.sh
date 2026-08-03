#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

STARSHIP_CONFIG_FILE="$XDG_CONFIG_HOME/starship.toml"
STARSHIP_PRESET_FILE="$XDG_STATE_HOME/zsh/starship-preset"
STARSHIP_BIN="$HOME/.local/bin/starship"

starship_command() {
	if is_command_available starship; then
		printf '%s\n' starship
	elif [ -x "$STARSHIP_BIN" ]; then
		printf '%s\n' "$STARSHIP_BIN"
	else
		return 1
	fi
}

choose_starship_preset() {
	local starship_cmd preset choice
	starship_cmd="$(starship_command)" || return 0

	printf '\nSelect a Starship preset:\n'
	select preset in nerd-font-symbols plain-text-symbols no-nerd-font gruvbox-rainbow pastel-powerline tokyo-night skip; do
		case "$preset" in
			skip)
				log "Skipped Starship preset configuration."
				return 0
				;;
			"")
				warn "Invalid option. Choose a number from the list."
				;;
			*)
				mkdir -p "$(dirname "$STARSHIP_CONFIG_FILE")"
				"$starship_cmd" preset "$preset" --output "$STARSHIP_CONFIG_FILE" --force
				mkdir -p "$(dirname "$STARSHIP_PRESET_FILE")"
				printf '%s\n' "$preset" > "$STARSHIP_PRESET_FILE"
				log "Starship preset configured: $preset"
				return 0
				;;
		esac
	done
}

if ! starship_command >/dev/null 2>&1; then
	if ! confirm_step "Install Starship?"; then
		warn "Starship installation skipped."
		exit 0
	fi
	if is_termux; then
		install_packages pkg starship
		record_owned_package pkg starship
	else
		installer="$(mktemp)"
		trap 'rm -f "$installer"' EXIT
		curl -fsSL https://starship.rs/install.sh -o "$installer"
		mkdir -p "$(dirname "$STARSHIP_BIN")"
		sh "$installer" -y -b "$HOME/.local/bin"
		record_owned_path "$STARSHIP_BIN"
	fi
fi

if [ -s "$STARSHIP_PRESET_FILE" ] && starship_command >/dev/null 2>&1; then
	read -r preset < "$STARSHIP_PRESET_FILE"
	mkdir -p "$(dirname "$STARSHIP_CONFIG_FILE")"
	"$(starship_command)" preset "$preset" --output "$STARSHIP_CONFIG_FILE" --force
else
	choose_starship_preset
fi

log "Starship setup complete."
