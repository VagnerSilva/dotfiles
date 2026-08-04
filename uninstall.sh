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

remove_path() {
  local path="$1"
  local description="$2"

  if [[ -f "$path" || -L "$path" ]]; then
    rm -f -- "$path"
    log "Removed $description: $path"
  fi
}



remove_starship() {
  if [[ -f "$STARSHIP_CACHE_FILE" ]]; then
    rm -f -- "$STARSHIP_CACHE_FILE"
    log "Removed Starship shell cache: $STARSHIP_CACHE_FILE"
  fi

  if [[ -f "$STARSHIP_PRESET_FILE" ]]; then
    rm -f -- "$STARSHIP_PRESET_FILE"
    log "Removed pending Starship preset: $STARSHIP_PRESET_FILE"
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
  warn "This removes only Stow-managed links and project caches."
  warn "Installed tools, Git, repositories, fonts, and user configuration are preserved."

  if ! confirm "Continue with the uninstall?"; then
    log "Uninstall cancelled."
    return 0
  fi

  remove_stowed_links
  remove_starship

  # Never remove tools, repositories, fonts, or user configuration.
  # Only links created by this repository and its transient caches are removed.
  remove_path "$XDG_CACHE_HOME/zsh/direnv_hook.zsh" "direnv cache"
  remove_path "$XDG_CACHE_HOME/zsh/fnm_env.zsh" "fnm cache"
  remove_path "$XDG_CACHE_HOME/zsh/mise_activate.zsh" "mise cache"
  remove_path "$XDG_CACHE_HOME/zsh/atuin_init.zsh" "Atuin cache"
  remove_path "$XDG_CACHE_HOME/zsh/batman_env.zsh" "bat cache"
  remove_path "$XDG_CACHE_HOME/zsh/fzf.zsh" "fzf cache"
  remove_path "$XDG_CACHE_HOME/zsh/starship_init.zsh" "Starship cache"
  remove_path "$XDG_STATE_HOME/zsh/starship-preset" "Starship state"
  remove_path "$XDG_STATE_HOME/zsh/features/fzf-tab.enabled" "fzf-tab state"

  printf '\nUninstall completed.\n'
}

main "$@"
