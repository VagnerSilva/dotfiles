#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
FNM_INSTALL_DIR="${FNM_INSTALL_DIR:-$XDG_DATA_HOME/fnm}"
FNM_INSTALLER_URL="https://fnm.vercel.app/install"
is_fnm_installed() {
	if is_command_available fnm; then
		return 0
	fi
	if [ -x "$FNM_INSTALL_DIR/fnm" ]; then
		export PATH="$(dirname "$FNM_INSTALL_DIR/fnm"):$PATH"
		return 0
	fi
	return 1
}
if is_fnm_installed; then log "fnm is already installed."; exit 0; fi
if ! confirm_step "Install fnm?"; then warn "fnm installation skipped."; exit 0; fi
installer="$(mktemp)"; trap 'rm -f "$installer"' EXIT
download_ok=false
for attempt in 1 2 3 4 5; do
	log "Downloading fnm installer (attempt $attempt)..."
	if curl --proto '=https' --tlsv1.2 -LsSf --retry 5 --retry-delay 2 --connect-timeout 15 --max-time 180 "$FNM_INSTALLER_URL" -o "$installer"; then
		download_ok=true
		break
	fi
	warn "fnm download attempt $attempt failed."
	sleep $((attempt * 2))
done
if [ "$download_ok" != "true" ]; then
	error "Failed to download fnm installer after multiple attempts."
	error "Check your network or install fnm manually."
	exit 1
fi
mkdir -p "$FNM_INSTALL_DIR"
bash "$installer" --install-dir "$FNM_INSTALL_DIR" --skip-shell
[ -x "$FNM_INSTALL_DIR/fnm" ] || { error "fnm installation did not create $FNM_INSTALL_DIR/fnm"; exit 1; }
record_owned_path "$FNM_INSTALL_DIR"
integration_file="$ZDOTDIR/.config/zsh/rc/tools/fnm.zsh"
ensure_zsh_integration "rc/tools/fnm.zsh"
if [ ! -s "$integration_file" ]; then
	cat > "$integration_file" <<EOF
# fnm: Node version manager shell environment.
_fnm_bin="\${FNM_INSTALL_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/fnm}/fnm"
if [ -x "\$_fnm_bin" ]; then
  export PATH="\$(dirname "\$_fnm_bin"):\$PATH"
  _fnm_env_cache="\${XDG_CACHE_HOME:-$HOME/.cache}/zsh/fnm_env.zsh"
  if [ ! -s "\$_fnm_env_cache" ] || [ "\$_fnm_bin" -nt "\$_fnm_env_cache" ]; then
    "\$_fnm_bin" env --shell zsh > "\$_fnm_env_cache"
  fi
  [ -f "\$_fnm_env_cache" ] && source "\$_fnm_env_cache"
fi
unset _fnm_bin _fnm_env_cache
EOF
	log "fnm shell integration created at $integration_file"
fi
log "fnm installed at $FNM_INSTALL_DIR/fnm."
