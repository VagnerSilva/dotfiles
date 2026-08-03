#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup/common.sh"

FONT_NAME="${NERD_FONT_NAME:-Meslo}"
FONT_VERSION="${NERD_FONT_VERSION:-v3.2.1}"
FONT_REGULAR_FILE="MesloLGSNerdFont-Regular.ttf"
FONT_BOLD_FILE="MesloLGSNerdFont-Bold.ttf"
FONT_REGULAR_URL="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/${FONT_VERSION}/patched-fonts/Meslo/S/Regular/${FONT_REGULAR_FILE}"
FONT_BOLD_URL="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/${FONT_VERSION}/patched-fonts/Meslo/S/Bold/${FONT_BOLD_FILE}"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FONT_BASE_DIR="$XDG_DATA_HOME/fonts/NerdFonts"
FONT_DIR="$FONT_BASE_DIR/$FONT_NAME"
FONT_FAMILY="${NERD_FONT_FAMILY:-}"
FONT_FILE=""

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

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command not found: $cmd"
    return 1
  fi
}

font_already_installed() {
  [[ -f "$FONT_DIR/$FONT_REGULAR_FILE" && -f "$FONT_DIR/$FONT_BOLD_FILE" ]]
}

download_fonts() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' RETURN

  mkdir -p "$FONT_DIR"
  log "Downloading ${FONT_NAME} Nerd Font Regular and Bold (${FONT_VERSION})..."
  curl -fL "$FONT_REGULAR_URL" -o "$tmp_dir/$FONT_REGULAR_FILE"
  curl -fL "$FONT_BOLD_URL" -o "$tmp_dir/$FONT_BOLD_FILE"
  install -m 0644 "$tmp_dir/$FONT_REGULAR_FILE" "$FONT_DIR/$FONT_REGULAR_FILE"
  install -m 0644 "$tmp_dir/$FONT_BOLD_FILE" "$FONT_DIR/$FONT_BOLD_FILE"

  trap - RETURN
  rm -rf "$tmp_dir"
}

refresh_font_cache() {
  if command -v fc-cache >/dev/null 2>&1; then
    log "Refreshing font cache"
    fc-cache -f "$XDG_DATA_HOME/fonts" >/dev/null
  else
    warn "fc-cache not found. Reopen your terminal or refresh font cache manually."
  fi
}

resolve_font_metadata() {
  FONT_FILE="$(find "$FONT_DIR" -type f -iname '*Regular*.ttf' -print -quit 2>/dev/null || true)"
  if [[ -z "$FONT_FILE" ]]; then
    FONT_FILE="$(find "$FONT_DIR" -type f \( -name '*.ttf' -o -name '*.otf' \) -print -quit 2>/dev/null || true)"
  fi

  if [[ -z "$FONT_FAMILY" ]] && [[ -n "$FONT_FILE" ]] && command -v fc-scan >/dev/null 2>&1; then
    FONT_FAMILY="$(fc-scan --format '%{family}\n' "$FONT_FILE" 2>/dev/null | head -n 1)"
  fi
  FONT_FAMILY="${FONT_FAMILY:-MesloLGS Nerd Font}"
}

backup_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  cp -- "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"
}

configure_gnome_terminal() {
  command -v gsettings >/dev/null 2>&1 || return 0
  local profile
  profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)"
  [[ -n "$profile" ]] || return 0
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/" use-system-font false || { warn "Could not configure GNOME Terminal profile."; return 0; }
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/" font "${FONT_FAMILY} 11" || { warn "Could not set GNOME Terminal font."; return 0; }
  log "Configured GNOME Terminal font: $FONT_FAMILY"
}

configure_konsole() {
  local profile
  profile="$(find "$HOME/.local/share/konsole" -type f -name '*.profile' -print -quit 2>/dev/null || true)"
  [[ -n "$profile" ]] || return 0
  backup_file "$profile"
  if grep -q '^Font=' "$profile"; then
    sed -i "s|^Font=.*|Font=${FONT_FAMILY},11,-1,5,50,0,0,0,0,0|" "$profile"
  else
    printf '\nFont=%s,11,-1,5,50,0,0,0,0,0\n' "$FONT_FAMILY" >> "$profile"
  fi
  log "Configured Konsole font: $FONT_FAMILY"
}

configure_xfce_terminal() {
  local config="$HOME/.config/xfce4/terminal/terminalrc"
  [[ -f "$config" ]] || return 0
  backup_file "$config"
  if grep -q '^FontName=' "$config"; then
    sed -i "s|^FontName=.*|FontName=${FONT_FAMILY} 11|" "$config"
  else
    printf '\nFontName=%s 11\n' "$FONT_FAMILY" >> "$config"
  fi
  log "Configured XFCE Terminal font: $FONT_FAMILY"
}

configure_termux() {
  [[ -n "${TERMUX_VERSION:-}" || -d "$HOME/.termux" ]] || return 0
  [[ -n "$FONT_FILE" ]] || return 0
  mkdir -p "$HOME/.termux"
  cp -- "$FONT_FILE" "$HOME/.termux/font.ttf"
  command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings || true
  log "Configured Termux font: $FONT_FAMILY"
}

configure_json_terminal_settings() {
  local file="$1"
  local mode="$2"
  [[ -f "$file" ]] || return 0
  command -v python3 >/dev/null 2>&1 || { warn "python3 not found; skipped JSON terminal config: $file"; return 0; }
  backup_file "$file"
  if ! FONT_FAMILY="$FONT_FAMILY" JSON_MODE="$mode" python3 - "$file" <<'PY'
import json
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
font = os.environ["FONT_FAMILY"]
mode = os.environ["JSON_MODE"]

if mode == "vscode":
    key = '"terminal.integrated.fontFamily"'
    value = json.dumps(font, ensure_ascii=False)
    import re
    pattern = re.compile(r'("terminal\.integrated\.fontFamily"\s*:\s*)("(?:\\.|[^"\\])*")')
    if pattern.search(text):
        text = pattern.sub(r'\g<1>' + value, text, count=1)
    else:
        closing = text.rfind("}")
        if closing < 0:
            raise ValueError("settings file has no root object")
        body = text[:closing].rstrip()
        separator = "" if body.endswith(",") else ","
        text = body + separator + '\n    ' + key + ': ' + value + '\n' + text[closing:]
    path.write_text(text)
else:
    data = json.loads(text)
    profiles = data.setdefault("profiles", {})
    defaults = profiles.setdefault("defaults", {})
    defaults.setdefault("font", {})["face"] = font
    for profile in profiles.get("list", []):
        profile.setdefault("font", {})["face"] = font
    path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")
PY
  then
    warn "Could not update terminal JSON configuration: $file"
    return 0
  fi
  log "Configured $mode font: $FONT_FAMILY"
}

configure_windows_terminals() {
  local appdata localappdata windows_terminal vscode
  command -v cmd.exe >/dev/null 2>&1 || return 0
  appdata="$(cmd.exe /c echo %APPDATA% 2>/dev/null | tr -d '\r' | tail -n 1)"
  localappdata="$(cmd.exe /c echo %LOCALAPPDATA% 2>/dev/null | tr -d '\r' | tail -n 1)"
  [[ -n "$appdata" && -n "$localappdata" ]] || return 0
  windows_terminal="$(wslpath -u "$appdata/Microsoft/Windows Terminal/settings.json" 2>/dev/null || true)"
  vscode="$(wslpath -u "$appdata/Code/User/settings.json" 2>/dev/null || true)"
  configure_json_terminal_settings "$windows_terminal" windows-terminal
  configure_json_terminal_settings "$vscode" vscode

  if [[ -n "$FONT_FILE" ]] && command -v powershell.exe >/dev/null 2>&1; then
    local windows_font_dir windows_font_file
    windows_font_dir="$(wslpath -u "$localappdata/Microsoft/Windows/Fonts" 2>/dev/null || true)"
    if [[ -z "$windows_font_dir" ]]; then
      warn "Could not resolve the Windows user fonts directory."
      return 0
    fi
    windows_font_file="$windows_font_dir/$(basename "$FONT_FILE")"
    mkdir -p "$windows_font_dir"
    if ! cp -- "$FONT_FILE" "$windows_font_file"; then
      warn "Could not copy the font to the Windows user fonts directory. Configure the terminal font manually in Windows."
      return 0
    fi
    powershell.exe -NoProfile -Command "New-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts' -Name '${FONT_FAMILY} (TrueType)' -Value \"\$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts\\$(basename "$FONT_FILE")\" -PropertyType String -Force | Out-Null" >/dev/null 2>&1 || warn "Could not register font in Windows user profile."
    log "Installed Windows font for detected terminals: $FONT_FAMILY"
  fi
}

configure_detected_terminals() {
  if ! confirm_step "Configure the Nerd Font as default in detected terminals?"; then
    log "Skipped terminal font configuration."
    return 0
  fi
  configure_gnome_terminal
  configure_konsole
  configure_xfce_terminal
  configure_termux
  configure_json_terminal_settings "$XDG_CONFIG_HOME/Code/User/settings.json" vscode
  configure_json_terminal_settings "$XDG_CONFIG_HOME/Code - OSS/User/settings.json" vscode
  configure_windows_terminals
}

main() {
  require_command curl
  require_command install

  if font_already_installed; then
    log "Nerd Font already installed: $FONT_NAME (Regular and Bold)"
  else
    download_fonts
    record_owned_path "$FONT_DIR"
    log "Nerd Font installation completed: $FONT_NAME (Regular and Bold)"
  fi

  refresh_font_cache
  resolve_font_metadata
  log "Detected font family: $FONT_FAMILY"
  configure_detected_terminals
}

main "$@"