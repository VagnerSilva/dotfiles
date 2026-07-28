#!/usr/bin/env bash

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ZDOTDIR="$XDG_CONFIG_HOME/zsh"

ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
ZINIT_REPO_URL="https://github.com/zdharma-continuum/zinit.git"
ZINIT_ENTRYPOINT="$ZINIT_HOME/zinit.zsh"
ZINIT_RC_FILE="$ZDOTDIR/rc/zinit.zsh"
ZINIT_PLUGIN_DIR="${ZINIT_PLUGIN_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zinit/plugins}"
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
STARSHIP_CONFIG_FILE="$XDG_CONFIG_HOME/starship.toml"
STARSHIP_PRESET_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/starship-preset"
STARSHIP_PRESETS=(
  bracketed-segments
  catppuccin-powerline
  gruvbox-rainbow
  jetpack
  nerd-font-symbols
  no-empty-icons
  no-nerd-font
  no-runtime-versions
  pastel-powerline
  plain-text-symbols
  pure-preset
  tokyo-night
)

# Installation policy:
# - Core dependencies are installed by package manager.
# - Managed tools are installed via zinit fallback rules in rc/zinit.zsh.
# - External tools are only reported here (user-managed install lifecycle).
MANAGED_TOOLS=(fnm fzf fd bat rg direnv cloc rename)
EXTERNAL_TOOLS=(mise broot qlty sdk)
FZF_TAB_FLAG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/features/fzf-tab.enabled"

log() {
  printf '[INFO] %s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

warn() {
  printf '[WARN] %s\n' "$1"
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
  printf '%s [y/N]: ' "$message"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

detect_package_manager() {
  if command -v pkg >/dev/null 2>&1; then
    echo "pkg"
  elif command -v apt-get >/dev/null 2>&1; then
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
    error "Required command not found: $cmd"
    return 1
  fi
}

is_command_available() {
  command -v "$1" >/dev/null 2>&1
}

detect_host_architecture() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "" ;;
  esac
}

ensure_supported_architecture() {
  local host_os
  local host_arch
  local word_size

  host_os="$(uname -s)"
  host_arch="$(detect_host_architecture)"
  word_size="$(getconf LONG_BIT 2>/dev/null || true)"
  if [ -z "$word_size" ]; then
     case "$(uname -m)" in aarch64|arm64|x86_64|amd64)
      word_size="64"
      ;;
      esac
  fi

  if [ "$host_os" != "Linux" ] && [ "$host_os" != "Darwin" ]; then
    error "Unsupported operating system for managed release binaries: $host_os"
    return 1
  fi

  if [ -z "$host_arch" ] || [ "$word_size" != "64" ]; then
    error "Unsupported CPU architecture: $(uname -m) (${word_size:-unknown}-bit)"
    error "Managed release binaries require a supported 64-bit x86_64 or arm64 host."
    return 1
  fi

  log "Compatible host detected: ${host_os}/${host_arch} (${word_size}-bit)"
}

install_dependencies() {
  local pm
  pm="$(detect_package_manager)"

  if [ -z "$pm" ]; then
    error "Could not detect package manager automatically."
    error "Install manually: git zsh curl tar gzip unzip xz"
    return 1
  fi

  log "Detected package manager: $pm"

  case "$pm" in
    pkg)
      pkg update -y
      pkg install -y git zsh curl tar gzip unzip xz-utils direnv
      ;;
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
      error "Unsupported package manager: $pm"
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
    log "zinit dependencies are already installed."
    return 0
  fi

  log "Missing dependencies: ${missing[*]}"
  install_dependencies
}

install_starship() {
  local installer
  local starship_bin="$HOME/.local/bin/starship"

  if command -v starship >/dev/null 2>&1 || [ -x "$starship_bin" ]; then
    log "Starship is already installed."
    return 0
  fi

  if ! confirm_step "Install the architecture-matched Starship binary?"; then
    warn "Starship installation skipped; the shell will use its fallback prompt."
    return 0
  fi

  installer="$(mktemp)"
  trap 'rm -f "$installer"' RETURN
  curl -fsSL https://starship.rs/install.sh -o "$installer"
  mkdir -p "$(dirname "$starship_bin")"
  sh "$installer" -y -b "$HOME/.local/bin"
  rm -f "$installer"
  trap - RETURN

  if [ ! -x "$starship_bin" ]; then
    error "Starship installation did not create $starship_bin"
    return 1
  fi

  "$starship_bin" --version
  log "Starship installed at $starship_bin"
}

verify_stow_layout() {
  if [ -f "$ZINIT_RC_FILE" ]; then
    log "Configuration file found at $ZINIT_RC_FILE"
    return 0
  fi

  error "Configuration file not found: $ZINIT_RC_FILE"
  error "Apply your zsh stow package before using zinit in shell startup."
  error "Example: stow zsh"
  return 1
}

ensure_parent_directory() {
  local parent_dir
  parent_dir="$(dirname "$ZINIT_HOME")"

  if [ ! -d "$parent_dir" ]; then
    log "Creating parent directory: $parent_dir"
    mkdir -p "$parent_dir"
  fi
}

clone_or_update_zinit() {
  if [ -d "$ZINIT_HOME/.git" ]; then
    log "zinit repository already exists at $ZINIT_HOME. Updating..."
    git -C "$ZINIT_HOME" pull --ff-only
    return 0
  fi

  if [ -d "$ZINIT_HOME" ] && [ ! -d "$ZINIT_HOME/.git" ]; then
    error "Directory $ZINIT_HOME exists, but is not a git repository."
    error "Remove or rename this directory and run again."
    return 1
  fi

  log "Cloning zinit into $ZINIT_HOME"
  git clone "$ZINIT_REPO_URL" "$ZINIT_HOME"
}

verify_installation() {
  if [ ! -f "$ZINIT_ENTRYPOINT" ]; then
    error "Incomplete installation: file not found at $ZINIT_ENTRYPOINT"
    return 1
  fi

  log "zinit ready at $ZINIT_HOME"
}

remove_compiled_plugin_cache() {
  if [ ! -d "$ZINIT_PLUGIN_DIR" ]; then
    return 0
  fi

  find "$ZINIT_PLUGIN_DIR" -type f -name '*.zwc' -delete
  log "Removed compiled Zinit plugin cache from $ZINIT_PLUGIN_DIR"
}

remove_zinit_starship_fallback() {
  local starship_plugin_dir="$ZINIT_PLUGIN_DIR/starship---starship"
  local legacy_starship_plugin_dir="$HOME/.local/shared/zinit/plugin/starship----startship"

  if [ -d "$starship_plugin_dir" ]; then
    rm -rf "$starship_plugin_dir"
    log "Removed Zinit-managed Starship fallback: $starship_plugin_dir"
  fi

  # Remove the directory created by an older, misspelled fallback reference.
  # The official installer target ($HOME/.local/bin/starship) is used instead.
  if [ -d "$legacy_starship_plugin_dir" ]; then
    rm -rf "$legacy_starship_plugin_dir"
    log "Removed malformed legacy Starship plugin: $legacy_starship_plugin_dir"
  fi

  rm -f "$ZSH_CACHE_DIR/starship_init.zsh"
}

configure_starship_preset() {
  local index
  local preset

  printf '\nAvailable Starship presets:\n'
  for index in "${!STARSHIP_PRESETS[@]}"; do
    printf ' %2d) %s\n' "$((index + 1))" "${STARSHIP_PRESETS[$index]}"
  done

  while true; do
    printf 'Choose a Starship preset [1-%d]: ' "${#STARSHIP_PRESETS[@]}"
    read -r index
    if [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= ${#STARSHIP_PRESETS[@]} )); then
      preset="${STARSHIP_PRESETS[$((index - 1))]}"
      break
    fi
    warn "Invalid selection. Choose a number from 1 to ${#STARSHIP_PRESETS[@]}."
  done

  mkdir -p "$(dirname "$STARSHIP_PRESET_FILE")"
  printf '%s\n' "$preset" > "$STARSHIP_PRESET_FILE"
  log "Starship preset selected: $preset"

  if command -v starship >/dev/null 2>&1; then
    mkdir -p "$(dirname "$STARSHIP_CONFIG_FILE")"
    starship preset "$preset" --output "$STARSHIP_CONFIG_FILE" --force
    rm -f -- "$STARSHIP_PRESET_FILE"
    log "Starship configuration generated at $STARSHIP_CONFIG_FILE"
  else
    log "Starship is managed by zinit and will apply this preset on first shell load."
  fi
}

install_managed_tools() {
  log "Managed tools will be installed via zinit on first shell load."
}

report_external_tool_status() {
  local tool
  local missing_tools=()

  for tool in "${EXTERNAL_TOOLS[@]}"; do
    if ! is_command_available "$tool"; then
      missing_tools+=("$tool")
    fi
  done

  if [ "${#missing_tools[@]}" -eq 0 ]; then
    log "External tools found: ${EXTERNAL_TOOLS[*]}"
  else
    warn "External tools not installed by this script: ${missing_tools[*]}"
  fi
}

configure_optional_fzf_tab() {
  if [ -f "$FZF_TAB_FLAG_FILE" ]; then
    log "Current fzf-tab status: enabled"
  else
    log "Current fzf-tab status: disabled"
  fi

  if confirm_step "Enable fzf-tab plugin (fuzzy tab-completion UI)?"; then
    mkdir -p "$(dirname "$FZF_TAB_FLAG_FILE")"
    : > "$FZF_TAB_FLAG_FILE"
    log "fzf-tab enabled."
  else
    rm -f "$FZF_TAB_FLAG_FILE"
    log "fzf-tab disabled."
  fi
}

install_optional_plugins() {
  if [ -f "$FZF_TAB_FLAG_FILE" ]; then
    log "Optional plugins enabled. They will load on next shell startup."
  fi
}

main() {
  print_title "Zinit setup"
  log "Interactive installation with optional plugin toggles."

  ensure_supported_architecture

  print_step "Step 1/4 - Starship binary"
  install_starship

  print_step "Step 2/4 - Starship preset"
  configure_starship_preset

  print_step "Step 3/4 - optional plugins"
  configure_optional_fzf_tab

  print_step "Step 4/4 - zinit and managed tools"
  ensure_dependencies
  require_command git
  verify_stow_layout
  ensure_parent_directory
  clone_or_update_zinit
  verify_installation
  remove_compiled_plugin_cache
  remove_zinit_starship_fallback
  install_managed_tools
  install_optional_plugins
  report_external_tool_status

  printf '\nNext step:\n'
  printf ' - Open a new zsh shell to load %s\n' "$ZINIT_RC_FILE"
}

main "$@"
