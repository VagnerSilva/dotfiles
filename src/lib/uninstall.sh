#!/usr/bin/env bash

# Uninstall safety helpers for the dotfiles CLI.
# Source this AFTER setup/common.sh. It defines SCRIPT_DIR (the repository
# root) and the pure functions exercised by the uninstall command and by the
# Bats test suite (tests/uninstall.bats).

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# Fallback for environments without readlink -f (e.g. macOS, BusyBox).
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Caller-visible state files; derive from setup/common.sh when not already set.
: "${owned_paths_file:=${DOTFILES_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles}/owned-paths}"
: "${owned_packages_file:=${DOTFILES_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles}/owned-packages}"

confirm() {
	local message="$1" answer
	[ "${ASSUME_YES:-false}" = true ] && return 0
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
	if [ "${DRY_RUN:-false}" = true ]; then log "Would remove $description: $path"; return 0; fi
	rm -rf -- "$path"
	log "Removed $description: $path"
}

is_owned_path() {
	local path="$1"
	[ -f "$owned_paths_file" ] || return 1
	grep -Fqx -- "$path" "$owned_paths_file"
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
		target="$HOME/$relative_path"
		if is_owned_link "$target"; then
			remove_path "$target" "dotfiles link"
		fi
	done < <(
		find "$SCRIPT_DIR" -mindepth 1 \
			-path "$SCRIPT_DIR/.git" -prune -o \
			-path "$SCRIPT_DIR/setup" -prune -o \
			-path "$SCRIPT_DIR/src" -prune -o \
			-path "$SCRIPT_DIR/bin" -prune -o \
			-name 'setup-*.sh' -prune -o \
			-name 'uninstall.sh' -prune -o \
			-name 'settings.yml' -prune -o \
			\( -type f -o -type d \) -print0
	)
}

remove_owned_tools() {
	local path manager package
	if [ -f "$owned_paths_file" ]; then
		while IFS= read -r path; do
			[ -n "$path" ] || continue
			remove_owned_path "$path" "user-installed terminal tool"
		done < "$owned_paths_file"
	fi

	[ -f "$owned_packages_file" ] || return 0
	if ! [ "${REMOVE_TOOLS:-false}" = true ]; then
		warn "System packages preserved. Use --tools to remove packages installed by this project."
		return 0
	fi
	while IFS=: read -r manager package; do
		[ -n "$manager" ] && [ -n "$package" ] || continue
		case "$package" in git|curl|zsh|stow) warn "Protected system package: $package"; continue ;; esac
		if [ "${DRY_RUN:-false}" = true ]; then
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
	done < "$owned_packages_file"
}
