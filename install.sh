#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_ZSH="$SCRIPT_DIR/setup-zsh.sh"
SETUP_ZINIT="$SCRIPT_DIR/setup-zinit.sh"
SETUP_NERD_FONT="$SCRIPT_DIR/setup-nerd-font.sh"
DEBUG_ZSH_BUS_ERROR="$SCRIPT_DIR/debug-zsh-bus-error.sh"

log() {
  printf '[INFO] %s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

print_title() {
  printf '\n### %s ###\n' "$1"
}

print_step() {
  printf '%s\n' "$1"
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

  print_step "$title"
  bash "$script"
}

main() {
  print_title "Dotfiles installation"
  log "This installer will guide you through zsh, zinit and Nerd Font setup."

  require_file "$SETUP_ZSH"
  require_file "$SETUP_ZINIT"
  require_file "$SETUP_NERD_FONT"
  require_file "$DEBUG_ZSH_BUS_ERROR"

  run_step "Step 1/3 - zsh setup" "$SETUP_ZSH"
  run_step "Step 2/3 - zinit setup" "$SETUP_ZINIT"
  run_step "Step 3/3 - Nerd Font setup" "$SETUP_NERD_FONT"

  printf '\nDone.\n'
  printf 'Open a new zsh session to apply all changes.\n'
  printf 'If startup tracing was enabled, inspect logs in %s/zsh/debug.\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

main "$@"
