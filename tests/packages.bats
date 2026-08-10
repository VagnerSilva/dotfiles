#!/usr/bin/env bats
# Tests for the tool package-name mapping in setup/tools/packages.sh.

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
