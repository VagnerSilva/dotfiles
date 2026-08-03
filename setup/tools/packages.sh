#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

manager="$(detect_package_manager)"
[ -n "$manager" ] || { error "No supported package manager found."; exit 1; }

packages=(fzf fd bat ripgrep direnv cloc zoxide atuin gh)
missing=()
install_names=()
for package in "${packages[@]}"; do
	case "$package" in
		fd)
			if [ "$manager" = apt ]; then command_name=fdfind; install_name=fd-find; else command_name=fd; install_name=fd; fi
			;;
		bat)
			if [ "$manager" = apt ]; then command_name=batcat; install_name=bat; else command_name=bat; install_name=bat; fi
			;;
		ripgrep) command_name=rg; install_name=ripgrep ;;
		*) command_name="$package"; install_name="$package" ;;
	esac

	if ! is_command_available "$command_name"; then
		if [ "$manager" = apt ] && [ "$package" = atuin ]; then
			warn "Package atuin is not available in the APT repositories; skipping it."
			continue
		fi
		missing+=("$package")
		install_names+=("$install_name")
	fi
done

[ "${#missing[@]}" -eq 0 ] && { log "CLI packages are already installed or unavailable in this package manager."; exit 0; }
if ! confirm_step "Install missing CLI packages (${missing[*]})?"; then
	warn "CLI package installation skipped."
	exit 0
fi
install_packages "$manager" "${install_names[@]}"
for package in "${missing[@]}"; do
	record_owned_package "$manager" "$package"
done
