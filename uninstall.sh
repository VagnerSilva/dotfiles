#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -x "$SCRIPT_DIR/bin/dotfiles" ]; then
	printf '[ERROR] %s\n' "bin/dotfiles not found; run 'bashly generate' first." >&2
	exit 1
fi

exec "$SCRIPT_DIR/bin/dotfiles" uninstall "$@"
