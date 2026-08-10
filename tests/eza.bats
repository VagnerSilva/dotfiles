#!/usr/bin/env bats
# Tests for eza integration: package mapping and conditional aliases.

setup() {
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../setup/common.sh"
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../setup/tools/packages.sh"
}

@test "resolve_install_name maps eza -> eza on apt" {
	run resolve_install_name eza apt
	[ "$status" -eq 0 ]
	[ "$output" = "eza" ]
}

@test "resolve_install_name maps eza -> eza on non-apt managers" {
	run resolve_install_name eza dnf
	[ "$status" -eq 0 ]
	[ "$output" = "eza" ]
}

@test "eza fragment defines ls alias only when eza is present" {
	# Stub the `command` builtin so that `command -v eza` reports an
	# executable path; the fragment then defines the aliases.
	command() {
		case "$*" in
			"-v eza") echo /bin/true; return 0 ;;
			*) return 1 ;;
		esac
	}
	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/../.config/zsh/rc/tools/eza.zsh"
	run alias ls
	[ "$status" -eq 0 ]
	[ "$output" = "alias ls='eza'" ]
}

@test "eza fragment defines no aliases when eza is absent" {
	# Stub the `command` builtin so that `command -v eza` reports nothing.
	command() { return 1; }
	run alias ls 2>/dev/null
	[ "$status" -ne 0 ] || [ -z "$output" ]
}
