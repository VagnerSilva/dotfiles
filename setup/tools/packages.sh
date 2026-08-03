#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
manager="$(detect_package_manager)"
[ -n "$manager" ] || { error "No supported package manager found."; exit 1; }
packages=(fzf fd bat ripgrep direnv cloc zoxide atuin gh)
missing=()
for package in "${packages[@]}"; do
	case "$package" in ripgrep) command_name=rg ;; *) command_name="$package" ;; esac
	is_command_available "$command_name" || missing+=("$package")
done
[ "${#missing[@]}" -eq 0 ] && { log "CLI packages are already installed."; exit 0; }
if ! confirm_step "Install missing CLI packages (${missing[*]})?"; then warn "CLI package installation skipped."; exit 0; fi
install_packages "$manager" "${missing[@]}"
for package in "${missing[@]}"; do
	record_owned_package "$manager" "$package"
done
