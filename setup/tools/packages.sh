#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# Map a tool's command name to the package name used by the detected manager.
# On Debian/Ubuntu the binaries `fd` and `bat` ship in packages named
# `fd-find` and `bat` respectively, so the uninstall step must record the
# package name, not the bare command name.
resolve_install_name() {
	local command_name="$1" manager="${2:-}"
	case "$command_name" in
		fd)  [ "$manager" = apt ] && printf 'fd-find' || printf 'fd' ;;
		bat) printf 'bat' ;;
		*)   printf '%s' "$command_name" ;;
	esac
}

install_atuin() {
	if is_command_available atuin; then
		log "atuin is already installed."
		return 0
	fi
	if ! confirm_step "Install atuin?"; then
		warn "atuin installation skipped."
		return 0
	fi
	# Prefer the package manager; fall back to the official installer when the
	# package is not available (e.g. atuin is absent from Debian/Ubuntu repos).
	if install_packages "$manager" atuin && is_command_available atuin; then
		record_owned_package "$manager" atuin
		return 0
	fi
	log "atuin is not available via $manager; using the official installer."
	install_atuin_from_official_installer
}

install_atuin_from_official_installer() {
	local tmp_dir
	require_command curl || return 1
	tmp_dir="$(mktemp -d)"
	trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

	# The official installer appends 'eval "$(atuin init zsh)"' to $ZDOTDIR/.zshrc.
	# Shell integration is managed by rc/tools/atuin.zsh, so isolate that edit in
	# a throwaway ZDOTDIR instead of polluting the stowed .zshrc.
	if ! (
		export ZDOTDIR="$tmp_dir"
		curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
	); then
		error "Official atuin installer failed."
		return 1
	fi
	[ -x "$HOME/.atuin/bin/atuin" ] || { error "atuin installation did not create $HOME/.atuin/bin/atuin"; return 1; }

	# ~/.atuin/bin is not on PATH; expose the binary via ~/.local/bin (project convention).
	mkdir -p "$HOME/.local/bin"
	ln -sf "$HOME/.atuin/bin/atuin" "$HOME/.local/bin/atuin"
	record_owned_path "$HOME/.atuin"
	record_owned_path "$HOME/.local/bin/atuin"
	log "atuin installed at $HOME/.local/bin/atuin."
	log "If the setup wizard did not run, execute 'atuin setup'."
}

main() {
	manager="$(detect_package_manager)"
	[ -n "$manager" ] || { error "No supported package manager found."; exit 1; }

	# Force regeneration after installation or package upgrades.
	if is_command_available direnv; then
		rm -f -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/direnv_hook.zsh"
	fi

	local packages=(fzf fd bat ripgrep direnv cloc zoxide gh)
	local missing=() install_names=()
	for package in "${packages[@]}"; do
		local command_name="$package"
		case "$package" in
			fd)  [ "$manager" = apt ] && command_name=fdfind || command_name=fd ;;
			bat) [ "$manager" = apt ] && command_name=batcat || command_name=bat ;;
			ripgrep) command_name=rg ;;
		esac
		if ! is_command_available "$command_name"; then
			missing+=("$package")
			install_names+=("$(resolve_install_name "$package" "$manager")")
		fi
	done

	if [ "${#missing[@]}" -eq 0 ]; then
		log "CLI packages are already installed or unavailable in this package manager."
	elif ! confirm_step "Install missing CLI packages (${missing[*]})?"; then
		warn "CLI package installation skipped."
	else
		install_packages "$manager" "${install_names[@]}"
		# Record the distro package name so uninstall can remove the correct package.
		for package in "${install_names[@]}"; do
			record_owned_package "$manager" "$package"
		done
	fi

	install_atuin
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	main "$@"
fi
