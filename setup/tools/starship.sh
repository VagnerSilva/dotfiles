#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

STARSHIP_CONFIG_FILE="$XDG_CONFIG_HOME/starship.toml"
STARSHIP_PRESET_FILE="$XDG_STATE_HOME/zsh/starship-preset"
STARSHIP_BIN="$HOME/.local/bin/starship"
STARSHIP_VERSION="${STARSHIP_VERSION:-1.23.0}"

starship_asset() {
	if [ -n "${STARSHIP_ASSET:-}" ]; then
		printf '%s\n' "$STARSHIP_ASSET"
		return 0
	fi

	case "$(uname -s):$(uname -m)" in
		Linux:x86_64) printf '%s\n' starship-x86_64-unknown-linux-gnu.tar.gz ;;
		Linux:aarch64|Linux:arm64) printf '%s\n' starship-aarch64-unknown-linux-musl.tar.gz ;;
		Darwin:x86_64) printf '%s\n' starship-x86_64-apple-darwin.tar.gz ;;
		Darwin:arm64) printf '%s\n' starship-aarch64-apple-darwin.tar.gz ;;
		*)
			error "Unsupported platform for Starship: $(uname -s)/$(uname -m). Set STARSHIP_ASSET."
			return 1
			;;
	esac
}

starship_command() {
	if is_command_available starship; then
		printf '%s\n' starship
	elif [ -x "$STARSHIP_BIN" ]; then
		printf '%s\n' "$STARSHIP_BIN"
	else
		return 1
	fi
}

install_starship_from_package_manager() {
	local manager
	manager="$(detect_package_manager)"
	[ -n "$manager" ] || return 1
	install_packages "$manager" starship
	is_command_available starship
}

choose_starship_preset() {
	# shellcheck disable=SC2034
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
		installed=false
		if is_command_available curl && is_command_available tar; then
			asset="$(starship_asset)"
			url="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/${asset}"
			if curl -fsSL --retry 3 "$url" -o "$archive"; then
				mkdir -p "$(dirname "$STARSHIP_BIN")"
				tar -xzf "$archive" -C "$(dirname "$STARSHIP_BIN")"
				if [ -x "$STARSHIP_BIN" ]; then
					record_owned_path "$STARSHIP_BIN"
					installed=true
				fi
			fi
		fi
		if [ "$installed" != true ] && install_starship_from_package_manager; then
			record_owned_package "$(detect_package_manager)" starship
			installed=true
		fi
		[ "$installed" = true ] || {
			error "Starship installation failed."
			error "Asset: v${STARSHIP_VERSION}/${asset:-unavailable}"
			exit 1
		}
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
