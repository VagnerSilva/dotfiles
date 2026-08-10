#!/usr/bin/env bats
# Tests for the tool package handling in setup/tools/packages.sh.

setup() {
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../setup/common.sh"
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../setup/tools/packages.sh"
}

@test "resolve_install_name maps fd -> fd-find on apt" {
	run resolve_install_name fd apt
	[ "$status" -eq 0 ]
	[ "$output" = "fd-find" ]
}

@test "resolve_install_name maps fd -> fd on non-apt managers" {
	run resolve_install_name fd dnf
	[ "$status" -eq 0 ]
	[ "$output" = "fd" ]
}

@test "resolve_install_name maps bat -> bat" {
	run resolve_install_name bat apt
	[ "$status" -eq 0 ]
	[ "$output" = "bat" ]
}

@test "resolve_install_name passes through unknown commands" {
	run resolve_install_name ripgrep apt
	[ "$status" -eq 0 ]
	[ "$output" = "ripgrep" ]
}

@test "main records the distro package name (fd -> fd-find on apt)" {
	# Stub the environment so 'fd'/'bat' are reported missing and the manager
	# is apt; drive main() and assert the recorded package uses fd-find.
	# (eza is installed by its own installer, not via this apt loop.)
	detect_package_manager() { echo apt; }
	is_command_available() { [ "$1" = "bar" ]; }   # everything else 'missing'
	install_packages() { :; }
	# Accept only the CLI package install prompt; decline the rest.
	confirm_step() { [[ "$1" == "Install missing CLI packages"* ]]; }
	XDG_STATE_HOME="$(mktemp -d)"
	DOTFILES_STATE_DIR="$XDG_STATE_HOME/dotfiles"
	OWNED_PACKAGES_FILE="$DOTFILES_STATE_DIR/owned-packages"
	mkdir -p "$DOTFILES_STATE_DIR"
	main

	run grep -qx "apt:fd-find" "$OWNED_PACKAGES_FILE"
	[ "$status" -eq 0 ]
}

@test "install_eza skips when eza is already present" {
	is_command_available() { [ "$1" = "eza" ] && return 0 || return 1; }
	run install_eza
	[ "$status" -eq 0 ]
}

@test "install_eza downloads release, installs to ~/.local/bin, and records the path" {
	# Simulate eza missing so the installer proceeds; stub network/sudo.
	is_command_available() { [ "$1" = "eza" ] && return 1 || return 0; }
	confirm_step() { return 0; }            # accept the eza prompt
	sudo() { :; }                           # best-effort exa symlink; ignore errors
	uname() { if [ "$1" = "-m" ]; then printf 'aarch64'; else command uname "$@"; fi; }
	curl() {
		# Capture the -o target and materialize a tar.gz containing 'eza'.
		local out="" i
		for ((i = 1; i <= $#; i++)); do
			if [ "${!i}" = "-o" ]; then
				eval "out=\${$((i + 1))}"
			fi
		done
		local d; d="$(mktemp -d)"
		printf '#!/bin/sh\necho eza-fake\n' > "$d/eza"
		chmod +x "$d/eza"
		tar -czf "$out" -C "$d" eza
		rm -rf "$d"
	}
	XDG_STATE_HOME="$(mktemp -d)"
	DOTFILES_STATE_DIR="$XDG_STATE_HOME/dotfiles"
	OWNED_PATHS_FILE="$DOTFILES_STATE_DIR/owned-paths"
	mkdir -p "$DOTFILES_STATE_DIR"
	HOME="$(mktemp -d)"

	run install_eza
	[ "$status" -eq 0 ]

	[ -x "$HOME/.local/bin/eza" ]
	run grep -Fqx "$HOME/.local/bin/eza" "$OWNED_PATHS_FILE"
	[ "$status" -eq 0 ]
}
