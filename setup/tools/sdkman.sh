#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
if is_command_available sdk; then log "SDKMAN is already installed."; exit 0; fi
if ! confirm_step "Install SDKMAN?"; then warn "SDKMAN installation skipped."; exit 0; fi
ensure_packages zip unzip
installer="$(mktemp)"; trap 'rm -f "$installer"' EXIT
download_ok=false
for attempt in 1 2 3 4 5; do
	log "Downloading SDKMAN installer (attempt $attempt)..."
	if curl --proto '=https' --tlsv1.2 -LsSf --retry 5 --retry-delay 2 --connect-timeout 15 --max-time 180 https://get.sdkman.io -o "$installer"; then
		download_ok=true
		break
	fi
	warn "SDKMAN download attempt $attempt failed."
	sleep $((attempt * 2))
done
if [ "$download_ok" != "true" ]; then
	error "Failed to download SDKMAN installer after multiple attempts."
	error "Check your network or install SDKMAN manually."
	exit 1
fi
SDKMAN_DIR="$SDKMAN_DIR" bash "$installer"
[ -f "$SDKMAN_DIR/bin/sdkman-init.sh" ] || { error "SDKMAN installation failed."; exit 1; }
record_owned_path "$SDKMAN_DIR"
log "SDKMAN installed at $SDKMAN_DIR."
