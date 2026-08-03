#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
FNM_INSTALL_DIR="${FNM_INSTALL_DIR:-$XDG_DATA_HOME/fnm}"
FNM_INSTALLER_URL="https://fnm.vercel.app/install"
if [ -x "$FNM_INSTALL_DIR/fnm" ] || is_command_available fnm; then log "fnm is already installed."; exit 0; fi
if ! confirm_step "Install fnm?"; then warn "fnm installation skipped."; exit 0; fi
installer="$(mktemp)"; trap 'rm -f "$installer"' EXIT
curl -fsSL "$FNM_INSTALLER_URL" -o "$installer"
mkdir -p "$FNM_INSTALL_DIR"; bash "$installer" --install-dir "$FNM_INSTALL_DIR" --skip-shell
[ -x "$FNM_INSTALL_DIR/fnm" ] || { error "fnm installation did not create $FNM_INSTALL_DIR/fnm"; exit 1; }
log "fnm installed at $FNM_INSTALL_DIR/fnm."
