#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
for installer in packages.sh starship.sh fnm.sh sdkman.sh; do bash "$SCRIPT_DIR/tools/$installer"; done
