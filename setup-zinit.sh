#!/usr/bin/env bash

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# For setup scripts, prefer HOME-scoped ZDOTDIR. Ignore inherited values that
# point outside HOME (common in sandbox or containerized validation).
if [ -n "${ZDOTDIR:-}" ] && [ "$ZDOTDIR" != "$HOME" ] && [[ "$ZDOTDIR" == "$HOME"/* ]]; then
  ZDOTDIR="$ZDOTDIR"
else
  ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi

ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
ZINIT_REPO_URL="https://github.com/zdharma-continuum/zinit.git"
ZINIT_ENTRYPOINT="$ZINIT_HOME/zinit.zsh"
ZINIT_RC_FILE="$ZDOTDIR/rc/zinit.zsh"

# Installation policy:
# - Core dependencies are installed by package manager.
# - Managed tools are installed via zinit fallback rules in rc/zinit.zsh.
# - External tools are only reported here (user-managed install lifecycle).
MANAGED_TOOLS=(fnm fzf starship fd bat rg direnv cloc rename)
EXTERNAL_TOOLS=(mise broot qlty sdk)
FZF_TAB_FLAG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/features/fzf-tab.enabled"

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_TITLE='\033[1;36m'
  C_STEP='\033[1;34m'
else
  C_RESET=''
  C_TITLE=''
  C_STEP=''
fi

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
  printf '\n%s%s%s\n' "$C_TITLE" "$1" "$C_RESET"
}

print_step() {
  printf '%s%s%s\n' "$C_STEP" "$1" "$C_RESET"
}

confirm_step() {
  local message="$1"
  local default_answer="${2:-N}"
  local answer=""
  local prompt_suffix='[y/N]'

  if [[ "$default_answer" == "Y" ]]; then
    prompt_suffix='[Y/n]'
  fi

  while true; do
    read -r -p "$message $prompt_suffix: " answer
    case "$answer" in
      y|Y|yes|YES)
        return 0
        ;;
      n|N|no|NO|"")
        if [[ -z "$answer" && "$default_answer" == "Y" ]]; then
          return 0
        fi
        return 1
        ;;
      *)
        warn "Invalid answer. Use y or n."
        ;;
    esac
  done
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
    error "Required command not found: $cmd"
    return 1
  fi
}

is_command_available() {
  command -v "$1" >/dev/null 2>&1
}

is_zsh_command_available() {
  local cmd="$1"
  ZDOTDIR="$ZDOTDIR" zsh -ic "command -v $cmd >/dev/null 2>&1" >/dev/null 2>&1
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

install_managed_tools() {
  local tool
  local missing_tools=()

  for tool in "${MANAGED_TOOLS[@]}"; do
    if ! is_zsh_command_available "$tool"; then
      missing_tools+=("$tool")
    fi
  done

  if [ "${#missing_tools[@]}" -eq 0 ]; then
    log "Managed tools already available: ${MANAGED_TOOLS[*]}"
    return 0
  fi

  log "Missing managed tools: ${missing_tools[*]}"
  log "Triggering zinit load once to install missing managed tools..."
  ZDOTDIR="$ZDOTDIR" zsh -ic 'true' >/dev/null

  missing_tools=()
  for tool in "${MANAGED_TOOLS[@]}"; do
    if ! is_zsh_command_available "$tool"; then
      missing_tools+=("$tool")
    fi
  done

  if [ "${#missing_tools[@]}" -eq 0 ]; then
    log "Managed tools installed successfully."
  else
    warn "Some managed tools are still missing: ${missing_tools[*]}"
    warn "Run 'zsh -ic true' and check zinit logs if needed."
  fi
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
  local default_answer="N"

  if [ -f "$FZF_TAB_FLAG_FILE" ]; then
    default_answer="Y"
    log "Current fzf-tab status: enabled"
  else
    log "Current fzf-tab status: disabled"
  fi

  if confirm_step "Enable fzf-tab plugin (fuzzy tab-completion UI)?" "$default_answer"; then
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
    log "Installing optional plugin: fzf-tab"
    ZDOTDIR="$ZDOTDIR" zsh -ic 'true' >/dev/null
  fi
}

main() {
  print_title "Zinit setup"
  log "Interactive installation with optional plugin toggles."

  print_step "Step 1/2 - optional plugins"
  configure_optional_fzf_tab

  print_step "Step 2/2 - zinit and managed tools"
  ensure_dependencies
  require_command git
  verify_stow_layout
  ensure_parent_directory
  clone_or_update_zinit
  verify_installation
  install_managed_tools
  install_optional_plugins
  report_external_tool_status

  printf '\nNext step:\n'
  printf ' - Open a new zsh shell to load %s\n' "$ZINIT_RC_FILE"
}

main "$@"
