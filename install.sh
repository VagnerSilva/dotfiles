#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_ZSH="$SCRIPT_DIR/setup-zsh.sh"
SETUP_ZINIT="$SCRIPT_DIR/setup-zinit.sh"
SETUP_NERD_FONT="$SCRIPT_DIR/setup-nerd-font.sh"

# Color codes (disabled if not interactive terminal)
C_RESET=''
C_TITLE=''
C_STEP=''
if [[ -t 1 ]] 2>/dev/null; then
  C_RESET='\033[0m'
  C_TITLE='\033[1;36m'
  C_STEP='\033[1;34m'
fi

log() {
  printf '[INFO] %s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

print_title() {
  printf '\n%s%s%s\n' "$C_TITLE" "$1" "$C_RESET"
}

print_step() {
  printf '%s%s%s\n' "$C_STEP" "$1" "$C_RESET"
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

  run_step "Step 1/3 - zsh setup" "$SETUP_ZSH"
  run_step "Step 2/3 - zinit setup" "$SETUP_ZINIT"
  run_step "Step 3/3 - Nerd Font setup" "$SETUP_NERD_FONT"

  printf '\nDone.\n'
  printf 'Open a new zsh session to apply all changes.\n'
}

main "$@"
