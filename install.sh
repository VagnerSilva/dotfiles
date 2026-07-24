#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_ZSH="$SCRIPT_DIR/setup-zsh.sh"
SETUP_ZINIT="$SCRIPT_DIR/setup-zinit.sh"
SETUP_NERD_FONT="$SCRIPT_DIR/setup-nerd-font.sh"

log() {
  printf '[INFO] %s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    error "Required file not found: $file"
    return 1
  fi
}

run_step() {
  local title="$1"
  local script="$2"

  log "$title"
  bash "$script"
}

main() {
  require_file "$SETUP_ZSH"
  require_file "$SETUP_ZINIT"
  require_file "$SETUP_NERD_FONT"

  run_step "Running zsh setup..." "$SETUP_ZSH"
  run_step "Running zinit setup..." "$SETUP_ZINIT"
  run_step "Running Nerd Font setup..." "$SETUP_NERD_FONT"

  printf '\nDone.\n'
  printf 'Open a new zsh session to apply all changes.\n'
}

main "$@"
