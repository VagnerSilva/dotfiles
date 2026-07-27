#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_TARGET="$HOME"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
ZINIT_DATA_DIR="${ZINIT_DATA_DIR:-$XDG_DATA_HOME/zinit}"
STARSHIP_PLUGIN_DIR="$ZINIT_DATA_DIR/plugins/starship---starship"
LEGACY_STARSHIP_PLUGIN_DIR="$HOME/.local/shared/zinit/plugin/starship----startship"
STARSHIP_CACHE_FILE="$XDG_CACHE_HOME/zsh/starship_init.zsh"
STARSHIP_PRESET_FILE="$XDG_STATE_HOME/zsh/starship-preset"
STARSHIP_BINARY="$HOME/.local/bin/starship"
FONT_NAME="${NERD_FONT_NAME:-Meslo}"
FONT_DIR="$XDG_DATA_HOME/fonts/NerdFonts/$FONT_NAME"
ASSUME_YES=false

log() {
  printf '[INFO] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1" >&2
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

confirm() {
  local message="$1"
  local answer

  if "$ASSUME_YES"; then
    return 0
  fi

  printf '%s [y/N]: ' "$message"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

is_owned_link() {
  local target="$1"
  local resolved

  [[ -L "$target" ]] || return 1
  resolved="$(readlink -f "$target" 2>/dev/null || true)"
  [[ "$resolved" == "$SCRIPT_DIR"/* ]]
}

remove_owned_link() {
  local target="$1"

  if is_owned_link "$target"; then
    rm -f "$target"
    log "Removed dotfiles link: $target"
  fi
}

remove_stowed_links() {
  local source
  local relative_path
  local target

  # Do not invoke `stow --delete`: it can wait on a missing or partial target
  # layout. Remove only links that resolve inside this repository instead.
  while IFS= read -r -d '' source; do
    relative_path="${source#"$SCRIPT_DIR"/}"
    target="$STOW_TARGET/$relative_path"
    remove_owned_link "$target"
  done < <(
    find "$SCRIPT_DIR" -mindepth 1 \
      -path "$SCRIPT_DIR/.git" -prune -o \
      -name 'setup-*.sh' -prune -o \
      -name 'uninstall.sh' -prune -o \
      \( -type f -o -type d \) -print0
  )
}

remove_directory() {
  local path="$1"
  local description="$2"

  if [[ -d "$path" ]]; then
    rm -rf "$path"
    log "Removed $description: $path"
  fi
}

remove_empty_directory() {
  local path="$1"

  rmdir "$path" 2>/dev/null || true
}

remove_starship() {
  remove_directory "$STARSHIP_PLUGIN_DIR" "Starship Zinit plugin"
  remove_directory "$LEGACY_STARSHIP_PLUGIN_DIR" "malformed legacy Starship plugin"

  if [[ -f "$STARSHIP_BINARY" ]]; then
    rm -f -- "$STARSHIP_BINARY"
    log "Removed Starship binary: $STARSHIP_BINARY"
  fi

  if [[ -f "$STARSHIP_CACHE_FILE" ]]; then
    rm -f -- "$STARSHIP_CACHE_FILE"
    log "Removed Starship shell cache: $STARSHIP_CACHE_FILE"
  fi

  if [[ -f "$STARSHIP_PRESET_FILE" ]]; then
    rm -f -- "$STARSHIP_PRESET_FILE"
    log "Removed pending Starship preset: $STARSHIP_PRESET_FILE"
  fi
}

refresh_font_cache() {
  if [[ -d "$XDG_DATA_HOME/fonts" ]] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$XDG_DATA_HOME/fonts" >/dev/null
  fi
}

restore_default_shell() {
  local bash_path

  bash_path="$(command -v bash 2>/dev/null || true)"
  if [[ -z "$bash_path" ]]; then
    warn "bash was not found; default shell was not changed."
    return 0
  fi

  if [[ "$SHELL" == "$bash_path" ]]; then
    log "The current default shell is already bash."
    return 0
  fi

  if "$ASSUME_YES"; then
    log "Kept the current default shell in non-interactive mode."
    return 0
  fi

  if confirm "Change the default shell to $bash_path?"; then
    chsh -s "$bash_path"
    log "Default shell changed to $bash_path. Sign out and back in to apply it."
  else
    log "Kept the current default shell."
  fi
}

parse_arguments() {
  while (($#)); do
    case "$1" in
      --yes)
        ASSUME_YES=true
        ;;
      --help|-h)
        printf 'Usage: %s [--yes]\n' "${BASH_SOURCE[0]}"
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        exit 2
        ;;
    esac
    shift
  done
}

main() {
  parse_arguments "$@"

  printf '\n### Dotfiles uninstall ###\n'
  warn "This removes Stow-managed links, Zinit, the managed Starship binary, Zsh cache/state, and the $FONT_NAME Nerd Font."
  warn "It does not uninstall system packages such as zsh, stow, git, or curl."

  if ! confirm "Continue with the uninstall?"; then
    log "Uninstall cancelled."
    return 0
  fi

  remove_stowed_links
  remove_starship

  remove_directory "$ZINIT_HOME" "Zinit repository"
  remove_directory "$ZINIT_DATA_DIR" "Zinit plugins and managed binaries"
  remove_directory "$XDG_CACHE_HOME/zsh" "Zsh cache"
  remove_directory "$XDG_STATE_HOME/zsh" "Zsh state"
  remove_directory "$FONT_DIR" "Nerd Font"

  remove_empty_directory "$XDG_CONFIG_HOME/zsh"
  remove_empty_directory "$XDG_CONFIG_HOME/eza"
  remove_empty_directory "$XDG_CONFIG_HOME/fzf-marks"
  refresh_font_cache
  restore_default_shell

  printf '\nUninstall completed.\n'
}

main "$@"
