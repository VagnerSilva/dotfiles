#!/usr/bin/env bash

set -euo pipefail

FONT_NAME="${NERD_FONT_NAME:-Meslo}"
FONT_VERSION="${NERD_FONT_VERSION:-v3.2.1}"
FONT_ZIP="${FONT_NAME}.zip"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${FONT_ZIP}"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
FONT_BASE_DIR="$XDG_DATA_HOME/fonts/NerdFonts"
FONT_DIR="$FONT_BASE_DIR/$FONT_NAME"

log() {
  printf '[INFO] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command not found: $cmd"
    return 1
  fi
}

font_already_installed() {
  [[ -d "$FONT_DIR" ]] && find "$FONT_DIR" -type f \( -name '*.ttf' -o -name '*.otf' \) | read -r
}

download_and_extract_font() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

  mkdir -p "$FONT_DIR"

  log "Downloading ${FONT_NAME} Nerd Font (${FONT_VERSION})..."
  curl -fL "$FONT_URL" -o "$tmp_dir/$FONT_ZIP"

  log "Extracting font files to $FONT_DIR"
  unzip -o "$tmp_dir/$FONT_ZIP" -d "$FONT_DIR" >/dev/null

  trap - RETURN
  rm -rf "$tmp_dir"
}

refresh_font_cache() {
  if command -v fc-cache >/dev/null 2>&1; then
    log "Refreshing font cache"
    fc-cache -f "$XDG_DATA_HOME/fonts" >/dev/null
  else
    warn "fc-cache not found. Reopen your terminal or refresh font cache manually."
  fi
}

main() {
  require_command curl
  require_command unzip

  if font_already_installed; then
    log "Nerd Font already installed: $FONT_NAME"
    refresh_font_cache
    return 0
  fi

  download_and_extract_font
  refresh_font_cache
  log "Nerd Font installation completed: $FONT_NAME"
  log "If your terminal supports profile fonts, set it to '${FONT_NAME} Nerd Font'."
}

main "$@"