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

confirm_step() {
  local message="$1"
  local answer=""

  while true; do
    read -r -p "$message [y/N]: " answer
    case "$answer" in
      y|Y|yes|YES)
        return 0
        ;;
      n|N|no|NO|"")
        return 1
        ;;
      *)
        warn "Resposta invalida. Use y ou n."
        ;;
    esac
  done
}

is_command_available() {
  command -v "$1" >/dev/null 2>&1
}

detect_package_manager() {
  if is_command_available apt-get; then
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
      error "Gerenciador de pacotes nao suportado: $pm"
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
    log "zsh ja esta listado em /etc/shells."
    return 0
  fi

  log "Adicionando $zsh_path em /etc/shells"
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
}

set_default_shell_to_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ "$SHELL" == "$zsh_path" ]]; then
    log "zsh ja e o shell padrao desta sessao ($SHELL)."
    return 0
  fi

  ensure_zsh_in_shells
  chsh -s "$zsh_path"
  log "Shell padrao alterado para $zsh_path."
  log "Abra uma nova sessao para aplicar completamente."
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
    stow --target="$STOW_TARGET" --restow --ignore='^\.git$' --ignore='^setup-.*\.sh$' .
  )

  log "Dotfiles linked with stow to $STOW_TARGET"
}

print_summary() {
  printf '\nResumo:\n'
  if is_zsh_installed; then
    printf ' - zsh instalado: sim (%s)\n' "$(command -v zsh)"
  else
    printf ' - zsh instalado: nao\n'
  fi

  if is_command_available stow; then
    printf ' - stow instalado: sim (%s)\n' "$(command -v stow)"
  else
    printf ' - stow instalado: nao\n'
  fi

  printf ' - shell atual (variavel SHELL): %s\n' "$SHELL"
  printf ' - destino de symlink: %s\n' "$STOW_TARGET"
}

main() {
  log "Script de instalacao e configuracao do zsh"
  print_summary

  if confirm_step "Deseja instalar o zsh (se necessario)?"; then
    ensure_zsh_installed
  else
    log "Etapa de instalacao ignorada."
  fi

  if confirm_step "Deseja instalar o stow (se necessario)?"; then
    ensure_stow_installed
  else
    log "Etapa de instalacao do stow ignorada."
  fi

  if confirm_step "Deseja definir o zsh como shell padrao?"; then
    set_default_shell_to_zsh
  else
    log "Etapa de shell padrao ignorada."
  fi

  if confirm_step "Deseja aplicar os dotfiles com stow?"; then
    apply_stow_layout
  else
    log "Etapa de aplicacao do stow ignorada."
  fi

  print_summary
  log "Concluido."
}

main "$@"