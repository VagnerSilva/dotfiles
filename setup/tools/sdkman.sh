#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
[ -f "$SDKMAN_DIR/bin/sdkman-init.sh" ] && { log "SDKMAN is already installed."; exit 0; }
if ! confirm_step "Install SDKMAN?"; then warn "SDKMAN installation skipped."; exit 0; fi
installer="$(mktemp)"; trap 'rm -f "$installer"' EXIT
curl -fsSL https://get.sdkman.io -o "$installer"; SDKMAN_DIR="$SDKMAN_DIR" bash "$installer"
[ -f "$SDKMAN_DIR/bin/sdkman-init.sh" ] || { error "SDKMAN installation failed."; exit 1; }
log "SDKMAN installed at $SDKMAN_DIR."
