#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reuse shared helpers (log/warn/error/confirm_step/is_termux/is_command_available/
# detect_package_manager/install_packages) instead of redefining them.
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

STOW_TARGET="$HOME"

print_title() {
	printf '\n### %s ###\n' "$1"
}

print_step() {
	printf '%s\n' "$1"
}

is_zsh_installed() {
	is_command_available zsh
}

ensure_zsh_installed() {
	if is_zsh_installed; then
		log "zsh already installed."
		return 0
	fi

	local pm
	pm="$(detect_package_manager)"

	if [[ -z "$pm" ]]; then
		error "Could not detect package manager automatically."
		error "Install zsh manually and run this script again."
		return 1
	fi

	log "Detected package manager: $pm"
	install_packages "$pm" zsh
}

ensure_stow_installed() {
	if is_command_available stow; then
		log "stow already installed."
		return 0
	fi

	local pm
	pm="$(detect_package_manager)"

	if [[ -z "$pm" ]]; then
		error "Could not detect package manager automatically."
		error "Install stow manually and run this script again."
		return 1
	fi

	log "Detected package manager: $pm"
	install_packages "$pm" stow
}

ensure_zsh_in_shells() {
	local zsh_path
	zsh_path="$(command -v zsh)"

	if grep -Fxq "$zsh_path" /etc/shells; then
		log "zsh is already listed in /etc/shells."
		return 0
	fi

	log "Adding $zsh_path to /etc/shells"
	if ! echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null; then
		warn "Could not update /etc/shells; chsh may fail."
		return 1
	fi
}

set_default_shell_to_zsh() {
	if ! is_zsh_installed; then
		error "zsh is not available; install it before changing the default shell."
		return 1
	fi

	if is_termux; then
		log "Termux detected. Skipping chsh."
		log "Start zsh manually with: zsh"
		return 0
	fi

	local zsh_path login_shell user_name
	zsh_path="$(command -v zsh)"
	user_name="${USER:-${LOGNAME:-$(id -un)}}"
	if is_command_available getent; then
		login_shell="$(getent passwd "$user_name" 2>/dev/null | cut -d: -f7 || true)"
	else
		login_shell=""
	fi
	login_shell="${login_shell:-${SHELL:-}}"

	if [[ "$login_shell" == "$zsh_path" ]]; then
		log "zsh is already the login shell ($login_shell)."
		return 0
	fi

	if ! ensure_zsh_in_shells; then
		warn "Continuing without changing the login shell."
		return 0
	fi
	if chsh -s "$zsh_path"; then
		log "Default shell changed to $zsh_path."
	else
		warn "Could not change the login shell with chsh. New Zsh sessions will still export SHELL=$zsh_path."
	fi
	log "Open a new session for full effect."
}

backup_stow_conflicts() {
	local source relative_path target backup

	while IFS= read -r -d '' source; do
		relative_path="${source#"$SCRIPT_DIR/"}"
		target="$STOW_TARGET/$relative_path"

		if [[ ! -e "$target" && ! -L "$target" ]]; then
			continue
		fi

		if [[ -L "$target" ]] && [[ "$(readlink -f "$target" 2>/dev/null || true)" == "$source" ]]; then
			continue
		fi

		if [[ -d "$target" && ! -L "$target" ]]; then
			continue
		fi

		backup="${target}.dotfiles-backup"
		mv -f -- "$target" "$backup"
		log "Backed up existing file: $target -> $backup"
	done < <(
		find "$SCRIPT_DIR" -type f \
			! -path "$SCRIPT_DIR/.git/*" \
			! -path "$SCRIPT_DIR/setup/*" \
			! -name 'setup-*.sh' \
			! -name 'install.sh' \
			! -name 'uninstall.sh' \
			-print0
	)
}

apply_stow_layout() {
	if ! is_command_available stow; then
		error "stow is not available; install it before applying dotfiles."
		return 1
	fi

	if [[ ! -f "$SCRIPT_DIR/.zshenv" ]]; then
		error "Missing file: $SCRIPT_DIR/.zshenv"
		return 1
	fi

	if [[ ! -d "$SCRIPT_DIR/.config/zsh" ]]; then
		error "Missing directory: $SCRIPT_DIR/.config/zsh"
		return 1
	fi

	backup_stow_conflicts

	(
		cd "$SCRIPT_DIR"
		stow --target="$STOW_TARGET" --restow --no-folding \
			--ignore='^\.git$' \
			--ignore='^setup$' \
			--ignore='^setup-.*\.sh$' \
			--ignore='^install\.sh$' \
			--ignore='^uninstall\.sh$' \
			--ignore='^src$' \
			--ignore='^bin$' \
			--ignore='^settings\.yml$' \
			.
	)

	log "Dotfiles linked with stow to $STOW_TARGET"
}

print_summary() {
	printf '\nSummary:\n'
	if is_zsh_installed; then
		printf ' - zsh installed: yes (%s)\n' "$(command -v zsh)"
	else
		printf ' - zsh installed: no\n'
	fi

	if is_command_available stow; then
		printf ' - stow installed: yes (%s)\n' "$(command -v stow)"
	else
		printf ' - stow installed: no\n'
	fi

	printf ' - current shell (SHELL): %s\n' "$SHELL"
	printf ' - symlink target: %s\n' "$STOW_TARGET"
}

main() {
	print_title "Zsh setup"
	log "Interactive installation with safe defaults."
	print_summary

	print_step "Step 1/4 - zsh package"
	if confirm_step "Install zsh (if needed)?"; then
		ensure_zsh_installed
	else
		log "Skipped zsh installation step."
	fi

	print_step "Step 2/4 - stow package"
	if confirm_step "Install stow (if needed)?"; then
		ensure_stow_installed
	else
		log "Skipped stow installation step."
	fi

	print_step "Step 3/4 - default shell"
	if confirm_step "Set zsh as default shell?"; then
		set_default_shell_to_zsh
	else
		log "Skipped default shell step."
	fi

	print_step "Step 4/4 - apply dotfiles"
	if confirm_step "Apply dotfiles with stow?"; then
		apply_stow_layout
	else
		log "Skipped stow apply step."
	fi

	print_summary
	log "Done."
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	main "$@"
fi
