#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_TARGET="$HOME"

log() {
  printf '[INFO] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
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

confirm_step() {
  local message="$1"
  local answer

  while true; do
    printf '%s [y/N]: ' "$message"
    if ! read -r answer; then
      warn "Input closed; using the safe default (No)."
      return 1
    fi
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      ""|n|N|no|NO) return 1 ;;
      *) warn "Invalid option. Enter y or n." ;;
    esac
  done
}

is_command_available() {
  command -v "$1" >/dev/null 2>&1
}

is_termux() {
  [[ -n "${TERMUX_VERSION:-}" ]]
}

detect_package_manager() {
  if is_termux; then
    echo "pkg"
  elif is_command_available apt-get; then
    echo "apt"
  elif is_command_available dnf; then
    echo "dnf"
  elif is_command_available yum; then
    echo "yum"
  elif is_command_available pacman; then
    echo "pacman"
  elif is_command_available zypper; then
    echo "zypper"
  elif is_command_available apk; then
    echo "apk"
  else
    echo ""
  fi
}

is_zsh_installed() {
  is_command_available zsh
}

install_packages() {
  local pm="$1"
  shift
  local packages=("$@")

  case "$pm" in
    pkg)
      pkg update -y
      pkg install -y "${packages[@]}"
      ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y "${packages[@]}"
      ;;
    dnf)
      sudo dnf install -y "${packages[@]}"
      ;;
    yum)
      sudo yum install -y "${packages[@]}"
      ;;
    pacman)
      sudo pacman -Sy --noconfirm "${packages[@]}"
      ;;
    zypper)
      sudo zypper --non-interactive install "${packages[@]}"
      ;;
    apk)
      sudo apk add "${packages[@]}"
      ;;
    *)
      error "Unsupported package manager: $pm"
      return 1
      ;;
  esac
}

ensure_zsh_installed() {
  if is_zsh_installed; then
    log "zsh already installed."
    return 0
  fi

  local pm
  pm="$(detect_package_manager)"

  if [[ -z "$pm" ]]; then
    error "Could not detect package manager automatically."
    error "Install zsh manually and run this script again."
    return 1
  fi

  log "Detected package manager: $pm"
  install_packages "$pm" zsh
}

ensure_stow_installed() {
  if is_command_available stow; then
    log "stow already installed."
    return 0
  fi

  local pm
  pm="$(detect_package_manager)"

  if [[ -z "$pm" ]]; then
    error "Could not detect package manager automatically."
    error "Install stow manually and run this script again."
    return 1
  fi

  log "Detected package manager: $pm"
  install_packages "$pm" stow
}

ensure_zsh_in_shells() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if grep -Fxq "$zsh_path" /etc/shells; then
    log "zsh is already listed in /etc/shells."
    return 0
  fi

  log "Adding $zsh_path to /etc/shells"
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
}

set_default_shell_to_zsh() {
  if is_termux; then
    log "Termux detected. Skipping chsh."
    log "Start zsh manually with: zsh"
    return 0
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ "$SHELL" == "$zsh_path" ]]; then
    log "zsh is already the default shell for this session ($SHELL)."
    return 0
  fi

  ensure_zsh_in_shells
  chsh -s "$zsh_path"

  log "Default shell changed to $zsh_path."
  log "Open a new session for full effect."
}

backup_current_zshrc() {
  return 0
}

apply_stow_layout() {
  if [[ ! -f "$SCRIPT_DIR/.zshenv" ]]; then
    error "Missing file: $SCRIPT_DIR/.zshenv"
    return 1
  fi

  if [[ ! -d "$SCRIPT_DIR/.config/zsh" ]]; then
    error "Missing directory: $SCRIPT_DIR/.config/zsh"
    return 1
  fi

  (
    cd "$SCRIPT_DIR"
    stow --target="$STOW_TARGET" --restow \
      --ignore='^\.git$' \
      --ignore='^setup$' \
      --ignore='^setup-.*\.sh$' \
      --ignore='^install\.sh$' \
      --ignore='^uninstall\.sh$' \
      .
  )

  log "Dotfiles linked with stow to $STOW_TARGET"
}

print_summary() {
  printf '\nSummary:\n'
  if is_zsh_installed; then
    printf ' - zsh installed: yes (%s)\n' "$(command -v zsh)"
  else
    printf ' - zsh installed: no\n'
  fi

  if is_command_available stow; then
    printf ' - stow installed: yes (%s)\n' "$(command -v stow)"
  else
    printf ' - stow installed: no\n'
  fi

  printf ' - current shell (SHELL): %s\n' "$SHELL"
  printf ' - symlink target: %s\n' "$STOW_TARGET"
}

main() {
  print_title "Zsh setup"
  log "Interactive installation with safe defaults."
  print_summary

  print_step "Step 1/4 - zsh package"
  if confirm_step "Install zsh (if needed)?"; then
    ensure_zsh_installed
  else
    log "Skipped zsh installation step."
  fi

  print_step "Step 2/4 - stow package"
  if confirm_step "Install stow (if needed)?"; then
    ensure_stow_installed
  else
    log "Skipped stow installation step."
  fi

  print_step "Step 3/4 - default shell"
  if confirm_step "Set zsh as default shell?"; then
    set_default_shell_to_zsh
  else
    log "Skipped default shell step."
  fi

  print_step "Step 4/4 - apply dotfiles"
  if confirm_step "Apply dotfiles with stow?"; then
    apply_stow_layout
  else
    log "Skipped stow apply step."
  fi

  print_summary
  log "Done."
}

main "$@"