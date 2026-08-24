#!/usr/bin/env bash

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
DOTFILES_STATE_DIR="${XDG_STATE_HOME}/dotfiles"
OWNED_PATHS_FILE="${DOTFILES_STATE_DIR}/owned-paths"
OWNED_PACKAGES_FILE="${DOTFILES_STATE_DIR}/owned-packages"

log() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1" >&2; }
error() { printf '[ERROR] %s\n' "$1" >&2; }

confirm_step() {
	local message="$1" answer
	while true; do
		printf '%s [y/N]: ' "$message"
		if ! read -r answer; then
			warn "Input closed; using the safe default (No)."
			return 1
		fi
		case "$answer" in
			y|Y|yes|YES) return 0 ;;
			""|n|N|no|NO) return 1 ;;
			*) warn "Invalid option. Enter y or n." ;;
		esac
	done
}

is_termux() {
	[ -n "${TERMUX_VERSION:-}" ] || [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ]
}

is_command_available() { command -v "$1" >/dev/null 2>&1; }

record_owned_path() {
	local path="$1"
	mkdir -p "$DOTFILES_STATE_DIR"
	grep -Fqx -- "$path" "$OWNED_PATHS_FILE" 2>/dev/null || printf '%s\n' "$path" >> "$OWNED_PATHS_FILE"
}

record_owned_package() {
	local manager="$1" package="$2"
	mkdir -p "$DOTFILES_STATE_DIR"
	grep -Fqx -- "$manager:$package" "$OWNED_PACKAGES_FILE" 2>/dev/null || printf '%s:%s\n' "$manager" "$package" >> "$OWNED_PACKAGES_FILE"
}

require_command() {
	if ! is_command_available "$1"; then
		error "Required command not found: $1"
		return 1
	fi
}

detect_package_manager() {
	if is_termux; then echo pkg
	elif is_command_available apt-get; then echo apt
	elif is_command_available dnf; then echo dnf
	elif is_command_available yum; then echo yum
	elif is_command_available pacman; then echo pacman
	elif is_command_available zypper; then echo zypper
	elif is_command_available apk; then echo apk
	elif is_command_available brew; then echo brew
	else echo ""
	fi
}

is_root() { [ "$(id -u)" -eq 0 ]; }

apk_ensure_repositories() {
	local repos_file="/etc/apk/repositories"
	if [ -s "$repos_file" ]; then
		return 0
	fi
	local alpine_version
	alpine_version="$(cat /etc/alpine-release 2>/dev/null | cut -d. -f1,2 || true)"
	if [ -z "$alpine_version" ]; then
		warn "Could not detect Alpine version; repositories not configured."
		return 1
	fi
	mkdir -p /etc/apk
	cat > "$repos_file" <<EOF
https://dl-cdn.alpinelinux.org/alpine/v${alpine_version}/main
https://dl-cdn.alpinelinux.org/alpine/v${alpine_version}/community
EOF
	log "Alpine repositories written to $repos_file"
}

apk_install() {
	if ! apk_ensure_repositories; then
		error "Alpine package repositories are not configured. Set /etc/apk/repositories manually."
		return 1
	fi
	apk update
	if is_root; then
		apk add --no-cache "$@"
	else
		require_command sudo
		sudo apk add --no-cache "$@"
	fi
}

install_packages() {
	local manager="$1"
	shift
	case "$manager" in
		pkg) pkg update -y; pkg install -y "$@" ;;
		brew) brew install "$@" ;;
		apt) sudo apt-get update; sudo apt-get install -y "$@" ;;
		dnf) sudo dnf install -y "$@" ;;
		yum) sudo yum install -y "$@" ;;
		pacman) sudo pacman -Sy --noconfirm "$@" ;;
		zypper) sudo zypper --non-interactive install "$@" ;;
		apk) apk_install "$@" ;;
		*) error "Unsupported package manager: ${manager:-none}"; return 1 ;;
	esac
}

ensure_packages() {
	local manager package missing=()
	manager="$(detect_package_manager)"
	[ -n "$manager" ] || { error "Could not detect package manager automatically."; return 1; }
	for package in "$@"; do
		is_command_available "$package" || missing+=("$package")
	done
	[ "${#missing[@]}" -eq 0 ] || install_packages "$manager" "${missing[@]}"
}
