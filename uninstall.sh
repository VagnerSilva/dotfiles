#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_TARGET="$HOME"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$XDG_STATE_HOME/dotfiles"
OWNED_PATHS_FILE="$STATE_DIR/owned-paths"
OWNED_PACKAGES_FILE="$STATE_DIR/owned-packages"
ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
ZINIT_DATA_DIR="${ZINIT_DATA_DIR:-$XDG_DATA_HOME/zinit}"
STARSHIP_CACHE_FILE="$XDG_CACHE_HOME/zsh/starship_init.zsh"
STARSHIP_PRESET_FILE="$XDG_STATE_HOME/zsh/starship-preset"
FONT_NAME="${NERD_FONT_NAME:-Meslo}"
FONT_DIR="$XDG_DATA_HOME/fonts/NerdFonts/$FONT_NAME"
ASSUME_YES=false
DRY_RUN=false
REMOVE_TOOLS=false

log() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1" >&2; }
error() { printf '[ERROR] %s\n' "$1" >&2; }

confirm() {
	local message="$1" answer
	if "$ASSUME_YES"; then return 0; fi
	while true; do
		printf '%s [y/N]: ' "$message"
		if ! read -r answer; then return 1; fi
		case "$answer" in
			y|Y|yes|YES) return 0 ;;
			""|n|N|no|NO) return 1 ;;
			*) warn "Invalid option. Enter y or n." ;;
		esac
	done
}

remove_path() {
	local path="$1" description="$2"
	[ -e "$path" ] || [ -L "$path" ] || return 0
	if "$DRY_RUN"; then log "Would remove $description: $path"; return 0; fi
	rm -rf -- "$path"
	log "Removed $description: $path"
}

is_owned_path() {
	local path="$1"
	[ -f "$OWNED_PATHS_FILE" ] || return 1
	grep -Fqx -- "$path" "$OWNED_PATHS_FILE"
}

remove_owned_path() {
	local path="$1" description="$2"
	if is_owned_path "$path"; then
		remove_path "$path" "$description"
	else
		[ -e "$path" ] || [ -L "$path" ] || return 0
		warn "Preserved $description (ownership not registered): $path"
	fi
}

is_owned_link() {
	local target="$1" resolved
	[[ -L "$target" ]] || return 1
	resolved="$(readlink -f "$target" 2>/dev/null || true)"
	[[ "$resolved" == "$SCRIPT_DIR"/* ]]
}

remove_stowed_links() {
	local source relative_path target
	while IFS= read -r -d '' source; do
		relative_path="${source#"$SCRIPT_DIR"/}"
		target="$STOW_TARGET/$relative_path"
		if is_owned_link "$target"; then
			remove_path "$target" "dotfiles link"
		fi
	done < <(
		find "$SCRIPT_DIR" -mindepth 1 \
			-path "$SCRIPT_DIR/.git" -prune -o \
			-path "$SCRIPT_DIR/setup" -prune -o \
			-name 'setup-*.sh' -prune -o \
			-name 'uninstall.sh' -prune -o \
			\( -type f -o -type d \) -print0
	)
}

remove_owned_tools() {
	local path manager package
	if [ -f "$OWNED_PATHS_FILE" ]; then
		while IFS= read -r path; do
			[ -n "$path" ] || continue
			remove_owned_path "$path" "user-installed terminal tool"
		done < "$OWNED_PATHS_FILE"
	fi

	[ -f "$OWNED_PACKAGES_FILE" ] || return 0
	if ! "$REMOVE_TOOLS"; then
		warn "System packages preserved. Use --tools to remove packages installed by this project."
		return 0
	fi
	while IFS=: read -r manager package; do
		[ -n "$manager" ] && [ -n "$package" ] || continue
		case "$package" in git|curl|zsh|stow) warn "Protected system package: $package"; continue ;; esac
		if "$DRY_RUN"; then
			log "Would remove package $manager:$package"
			continue
		fi
		case "$manager" in
			pkg) pkg uninstall -y "$package" ;;
			brew) brew uninstall "$package" ;;
			apt) sudo apt-get remove -y "$package" ;;
			dnf) sudo dnf remove -y "$package" ;;
			yum) sudo yum remove -y "$package" ;;
			pacman) sudo pacman -R --noconfirm "$package" ;;
			zypper) sudo zypper --non-interactive remove "$package" ;;
			apk) sudo apk del "$package" ;;
			*) warn "Unsupported package manager; preserved $manager:$package"; continue ;;
		esac
		log "Removed package $manager:$package"
	done < "$OWNED_PACKAGES_FILE"
}

parse_arguments() {
	while (($#)); do
		case "$1" in
			--yes) ASSUME_YES=true ;;
			--dry-run) DRY_RUN=true ;;
			--tools) REMOVE_TOOLS=true ;;
			--help|-h) printf 'Usage: %s [--dry-run] [--tools] [--yes]\n' "${BASH_SOURCE[0]}"; exit 0 ;;
			*) error "Unknown option: $1"; exit 2 ;;
		esac
		shift
	done
}

main() {
	parse_arguments "$@"
	printf '\n### Terminal Zsh uninstall ###\n'
	warn "System dependencies such as git, curl, zsh and stow are never removed."
	[ "$REMOVE_TOOLS" = true ] && warn "--tools removes only packages recorded as installed by this project."
	confirm "Continue with the terminal uninstall?" || { log "Uninstall cancelled."; return 0; }

	remove_stowed_links
	remove_path "$ZINIT_HOME" "Zinit repository"
	remove_path "$ZINIT_DATA_DIR" "Zinit plugins"
	remove_path "$XDG_CACHE_HOME/zsh" "Zsh cache"
	remove_path "$XDG_STATE_HOME/zsh" "Zsh state"
	remove_path "$STARSHIP_CACHE_FILE" "Starship cache"
	remove_path "$STARSHIP_PRESET_FILE" "Starship preset state"
	remove_owned_path "$FONT_DIR" "Nerd Font"
	remove_owned_tools
	remove_path "$STATE_DIR" "dotfiles ownership state"
	printf '\nUninstall completed.\n'
	warn "If this command was run from zsh, close this shell and open a new one so cached tool hooks are unloaded."
}

main "$@"
