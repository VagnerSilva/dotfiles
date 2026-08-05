#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

STARSHIP_CONFIG_FILE="$XDG_CONFIG_HOME/starship.toml"
STARSHIP_PRESET_FILE="$XDG_STATE_HOME/zsh/starship-preset"
STARSHIP_BIN="$HOME/.local/bin/starship"
STARSHIP_VERSION="${STARSHIP_VERSION:-1.23.0}"

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
				"$starship_cmd" preset "$preset" --output "$STARSHIP_CONFIG_FILE"
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
		archive="$(mktemp)"
		trap 'rm -f "$archive"' EXIT
		case "$(uname -s):$(uname -m)" in
			Linux:x86_64) asset="starship-x86_64-unknown-linux-gnu.tar.gz" ;;
			Linux:aarch64|Linux:arm64) asset="starship-aarch64-unknown-linux-gnu.tar.gz" ;;
			Darwin:x86_64) asset="starship-x86_64-apple-darwin.tar.gz" ;;
			Darwin:arm64) asset="starship-aarch64-apple-darwin.tar.gz" ;;
			*) error "Unsupported platform for Starship: $(uname -s)/$(uname -m)"; exit 1 ;;
		esac
		curl -fsSL --retry 3 "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/${asset}" -o "$archive"
		mkdir -p "$(dirname "$STARSHIP_BIN")"
		tar -xzf "$archive" -C "$(dirname "$STARSHIP_BIN")"
		[ -x "$STARSHIP_BIN" ] || { error "Starship archive did not install $STARSHIP_BIN"; exit 1; }
		record_owned_path "$STARSHIP_BIN"
	fi
fi

if [ -s "$STARSHIP_PRESET_FILE" ] && starship_command >/dev/null 2>&1; then
	read -r preset < "$STARSHIP_PRESET_FILE"
	mkdir -p "$(dirname "$STARSHIP_CONFIG_FILE")"
	"$(starship_command)" preset "$preset" --output "$STARSHIP_CONFIG_FILE"
else
	choose_starship_preset
fi

log "Starship setup complete."
