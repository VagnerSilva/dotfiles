#!/usr/bin/env bats
# Tests for uninstall safety (src/lib/uninstall.sh):
#  - dry-run must not destroy files
#  - protected system packages (git/zsh/stow) are never removed
#  - is_owned_link only matches symlinks pointing inside the repo

setup() {
	export XDG_STATE_HOME="$BATS_TMPDIR/uninstall-state-$BATS_TEST_NUMBER"
	export DOTFILES_STATE_DIR="$XDG_STATE_HOME/dotfiles"
	export owned_paths_file="$DOTFILES_STATE_DIR/owned-paths"
	export owned_packages_file="$DOTFILES_STATE_DIR/owned-packages"
	mkdir -p "$DOTFILES_STATE_DIR"
	export DRY_RUN=false
	export ASSUME_YES=false
	export REMOVE_TOOLS=false
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../setup/common.sh"
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../src/lib/uninstall.sh"
}

teardown() {
	rm -rf "$XDG_STATE_HOME"
}

@test "is_owned_link recognizes a symlink pointing inside the repo" {
	local target
	target="$(mktemp -d)"
	ln -s "$SCRIPT_DIR/.config" "$target/link"
	run is_owned_link "$target/link"
	[ "$status" -eq 0 ]
	rm -f "$target/link"; rmdir "$target"
}

@test "is_owned_link rejects a symlink pointing outside the repo" {
	local target
	target="$(mktemp -d)"
	ln -s "/etc/passwd" "$target/link"
	run is_owned_link "$target/link"
	[ "$status" -ne 0 ]
	rm -f "$target/link"; rmdir "$target"
}

@test "DRY_RUN prevents remove_path from deleting" {
	local canary
	canary="$(mktemp)"
	DRY_RUN=true
	remove_path "$canary" "canary"
	[ -f "$canary" ]
	rm -f "$canary"
}

@test "remove_path actually deletes when not dry-run" {
	local canary
	canary="$(mktemp)"
	DRY_RUN=false
	remove_path "$canary" "canary"
	[ ! -e "$canary" ]
}

@test "remove_owned_tools preserves protected system packages (git/zsh/stow)" {
	printf '%s\n' "apt:git" "apt:zsh" "apt:stow" > "$owned_packages_file"
	local removed=()
	apt() { [ "$1" = "remove" ] && removed+=("$2"); }
	REMOVE_TOOLS=true
	DRY_RUN=false
	remove_owned_tools
	[ "${#removed[@]}" -eq 0 ]
}

@test "remove_owned_tools removes non-protected packages when REMOVE_TOOLS" {
	printf '%s\n' "apt:fd-find" > "$owned_packages_file"
	local removed=()
	# Stub the real removal path (sudo apt-get remove ...) so the test never
	# touches the host package manager. bashly uninstall invokes `sudo apt-get remove -y PKG`.
	sudo() { "$@"; }
	apt-get() {
		local -a args=("$@")
		# last positional argument is the package name
		removed+=("${args[${#args[@]}-1]}")
	}
	REMOVE_TOOLS=true
	DRY_RUN=false
	remove_owned_tools
	[ "${#removed[@]}" -eq 1 ]
	[ "${removed[0]}" = "fd-find" ]
}

@test "remove_owned_tools never removes packages without --tools" {
	printf '%s\n' "apt:fd-find" > "$owned_packages_file"
	local removed=()
	apt() { [ "$1" = "remove" ] && removed+=("$2"); }
	REMOVE_TOOLS=false
	remove_owned_tools
	[ "${#removed[@]}" -eq 0 ]
}
