#!/usr/bin/env bash
set -euo pipefail
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SETUP_DIR/common.sh"
TOOLS_DIR="$SETUP_DIR/tools"
for installer in packages.sh starship.sh fnm.sh sdkman.sh; do bash "$TOOLS_DIR/$installer"; done
