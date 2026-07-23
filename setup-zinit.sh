#!/usr/bin/env bash

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
ZINIT_REPO_URL="https://github.com/zdharma-continuum/zinit.git"
ZINIT_ENTRYPOINT="$ZINIT_HOME/zinit.zsh"
ZINIT_RC_FILE="$ZDOTDIR/rc/zinit.zsh"

log() {
  printf '[INFO] %s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  else
    echo ""
  fi
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Comando obrigatorio nao encontrado: $cmd"
    return 1
  fi
}

install_dependencies() {
  local pm
  pm="$(detect_package_manager)"

  if [ -z "$pm" ]; then
    error "Nao foi possivel detectar o gerenciador de pacotes automaticamente."
    error "Instale manualmente: git zsh curl tar gzip unzip xz"
    return 1
  fi

  log "Gerenciador detectado: $pm"

  case "$pm" in
    apt)
      sudo apt-get update
      sudo apt-get install -y git zsh curl tar gzip unzip xz-utils
      ;;
    dnf)
      sudo dnf install -y git zsh curl tar gzip unzip xz
      ;;
    yum)
      sudo yum install -y git zsh curl tar gzip unzip xz
      ;;
    pacman)
      sudo pacman -Sy --noconfirm git zsh curl tar gzip unzip xz
      ;;
    zypper)
      sudo zypper --non-interactive install git zsh curl tar gzip unzip xz
      ;;
    apk)
      sudo apk add git zsh curl tar gzip unzip xz
      ;;
    *)
      error "Gerenciador de pacotes nao suportado: $pm"
      return 1
      ;;
  esac
}

ensure_dependencies() {
  local deps
  local dep
  local missing

  deps=(git zsh curl tar gzip unzip xz)
  missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    log "Dependencias do zinit ja estao instaladas."
    return 0
  fi

  log "Dependencias ausentes: ${missing[*]}"
  install_dependencies
}

verify_stow_layout() {
  if [ -f "$ZINIT_RC_FILE" ]; then
    log "Arquivo de configuracao encontrado em $ZINIT_RC_FILE"
    return 0
  fi

  error "Arquivo de configuracao nao encontrado: $ZINIT_RC_FILE"
  error "Aplique seu pacote stow de zsh antes de usar o zinit no shell."
  error "Exemplo: stow zsh"
  return 1
}

ensure_parent_directory() {
  local parent_dir
  parent_dir="$(dirname "$ZINIT_HOME")"

  if [ ! -d "$parent_dir" ]; then
    log "Criando diretorio pai: $parent_dir"
    mkdir -p "$parent_dir"
  fi
}

clone_or_update_zinit() {
  if [ -d "$ZINIT_HOME/.git" ]; then
    log "Repositorio zinit ja existe em $ZINIT_HOME. Atualizando..."
    git -C "$ZINIT_HOME" pull --ff-only
    return 0
  fi

  if [ -d "$ZINIT_HOME" ] && [ ! -d "$ZINIT_HOME/.git" ]; then
    error "Diretorio $ZINIT_HOME existe, mas nao e um repositorio git."
    error "Remova ou renomeie esse diretorio e execute novamente."
    return 1
  fi

  log "Clonando zinit em $ZINIT_HOME"
  git clone "$ZINIT_REPO_URL" "$ZINIT_HOME"
}

verify_installation() {
  if [ ! -f "$ZINIT_ENTRYPOINT" ]; then
    error "Instalacao incompleta: arquivo nao encontrado em $ZINIT_ENTRYPOINT"
    return 1
  fi

  log "Zinit pronto em $ZINIT_HOME"
}

main() {
  ensure_dependencies
  require_command git
  verify_stow_layout
  ensure_parent_directory
  clone_or_update_zinit
  verify_installation

  printf '\nProximo passo:\n'
  printf ' - Abra um novo shell zsh para carregar %s\n' "$ZINIT_RC_FILE"
}

main "$@"
