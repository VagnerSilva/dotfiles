# Shared Bats helpers: load project scripts in isolation.

PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# Source a script WITHOUT running its main(). We strip the
# `if [ "${BASH_SOURCE[0]}" = "${0}" ]; then main "$@"; fi` guard by sourcing
# the file in a context where BASH_SOURCE[0] != the file, which the guard
# already handles, so plain `source` is enough.
load_script() {
	local relpath="$1"
	# shellcheck source=/dev/null
	source "$PROJECT_ROOT/$relpath"
}
