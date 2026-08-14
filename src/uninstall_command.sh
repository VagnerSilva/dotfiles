#!/usr/bin/env bash

# shellcheck disable=SC2034
local ASSUME_YES=false
local DRY_RUN=false
local REMOVE_TOOLS=false
[ "${args[--yes]:-}" = 1 ] && ASSUME_YES=true
[ "${args[--dry-run]:-}" = 1 ] && DRY_RUN=true
[ "${args[--tools]:-}" = 1 ] && REMOVE_TOOLS=true

local script_dir state_dir owned_paths_file owned_packages_file
local zinit_home zinit_data_dir starship_cache_file starship_preset_file
local font_name font_dir

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=../setup/common.sh
source "$script_dir/setup/common.sh"
# shellcheck source=lib/uninstall.sh
source "$script_dir/src/lib/uninstall.sh"

state_dir="$XDG_STATE_HOME/dotfiles"
owned_paths_file="$state_dir/owned-paths"
owned_packages_file="$state_dir/owned-packages"
zinit_home="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
zinit_data_dir="${ZINIT_DATA_DIR:-$XDG_DATA_HOME/zinit}"
starship_cache_file="$XDG_CACHE_HOME/zsh/starship_init.zsh"
starship_preset_file="$XDG_STATE_HOME/zsh/starship-preset"
font_name="${NERD_FONT_NAME:-Meslo}"
font_dir="$XDG_DATA_HOME/fonts/NerdFonts/$font_name"

ui_title "Uninstall: dotfiles environment"
ui_warn "System dependencies such as git, curl, zsh and stow are never removed."
[ "$REMOVE_TOOLS" = true ] && ui_warn "--tools removes only packages recorded as installed by this project."
confirm "Continue with the terminal uninstall?" || { log "Uninstall cancelled."; return 0; }

ui_step "Removing dotfiles links and registered resources"
remove_stowed_links
remove_path "$zinit_home" "Zinit repository"
remove_path "$zinit_data_dir" "Zinit plugins"
remove_path "$XDG_CACHE_HOME/zsh" "Zsh cache"
remove_path "$XDG_STATE_HOME/zsh" "Zsh state"
remove_path "$starship_cache_file" "Starship cache"
remove_path "$starship_preset_file" "Starship preset state"
remove_owned_path "$font_dir" "Nerd Font"
remove_owned_tools
remove_path "$state_dir" "dotfiles ownership state"

printf '\n'
ui_ok "Uninstall completed. Restart the current shell with 'exec zsh -l' to unload the in-memory Starship hook."
