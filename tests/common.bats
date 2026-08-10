#!/usr/bin/env bats
# Tests for setup/common.sh helpers.

setup() {
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../setup/common.sh"
	# Isolate state dirs into the test's temp space.
	export XDG_STATE_HOME="$BATS_TMPDIR/common-state-$BATS_TEST_NUMBER"
	export DOTFILES_STATE_DIR="$XDG_STATE_HOME/dotfiles"
	export OWNED_PATHS_FILE="$DOTFILES_STATE_DIR/owned-paths"
	export OWNED_PACKAGES_FILE="$DOTFILES_STATE_DIR/owned-packages"
}

teardown() {
	rm -rf "$XDG_STATE_HOME"
}

@test "is_command_available detects present commands" {
	run is_command_available bash
	[ "$status" -eq 0 ]
}

@test "is_command_available misses absent commands" {
	run is_command_available this_command_does_not_exist_xyz
	[ "$status" -ne 0 ]
}

@test "is_termux is false in CI/test env" {
	run is_termux
	[ "$status" -ne 0 ]
}

@test "detect_package_manager falls back to empty string when none found" {
	# Stub is_command_available to report every manager missing.
	is_command_available() { return 1; }
	run detect_package_manager
	[ "$status" -eq 0 ]
	[ "$output" = "" ]
}

@test "record_owned_path appends exactly once" {
	record_owned_path "/tmp/foo"
	record_owned_path "/tmp/foo"
	run wc -l < "$OWNED_PATHS_FILE"
	[ "$output" -eq 1 ]
	grep -qx "/tmp/foo" "$OWNED_PATHS_FILE"
}

@test "record_owned_package records manager:package" {
	record_owned_package apt fd-find
	run cat "$OWNED_PACKAGES_FILE"
	[ "$output" = "apt:fd-find" ]
}

@test "ensure_packages installs only missing commands" {
	detect_package_manager() { echo apt; }
	# Every requested command is absent -> all are selected for install.
	is_command_available() { return 1; }
	local cap; cap="$(mktemp)"
	install_packages() { local m="$1"; shift; printf '%s\n' "$@" >> "$cap"; }
	run ensure_packages foo bar
	[ "$status" -eq 0 ]
	run cat "$cap"
	[ "$output" = "$(printf 'foo\nbar')" ]
}

@test "ensure_packages skips already-present commands" {
	detect_package_manager() { echo apt; }
	# 'bar' present, 'foo' missing -> only 'foo' selected.
	is_command_available() { [ "$1" = "bar" ]; }
	local cap; cap="$(mktemp)"
	install_packages() { local m="$1"; shift; printf '%s\n' "$@" >> "$cap"; }
	run ensure_packages foo bar
	[ "$status" -eq 0 ]
	run cat "$cap"
	[ "$output" = "foo" ]
}
