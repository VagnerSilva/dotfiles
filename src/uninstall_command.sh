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

state_dir="$XDG_STATE_HOME/dotfiles"
owned_paths_file="$state_dir/owned-paths"
owned_packages_file="$state_dir/owned-packages"
zinit_home="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
zinit_data_dir="${ZINIT_DATA_DIR:-$XDG_DATA_HOME/zinit}"
starship_cache_file="$XDG_CACHE_HOME/zsh/starship_init.zsh"
starship_preset_file="$XDG_STATE_HOME/zsh/starship-preset"
font_name="${NERD_FONT_NAME:-Meslo}"
font_dir="$XDG_DATA_HOME/fonts/NerdFonts/$font_name"

confirm() {
	local message="$1" answer
	if "$ASSUME_YES"; then return 0; fi
	while true; do
		printf '%s [y/N]: ' "$message"
		if ! read -r answer; then return 1; fi
		case "$answer" in
			y|Y|yes|YES) return 0 ;;
			""|n|N|no|NO) return 1 ;;
			*) warn "Invalid option. Enter y or n." ;;
		esac
	done
}

remove_path() {
	local path="$1" description="$2"
	[ -e "$path" ] || [ -L "$path" ] || return 0
	if "$DRY_RUN"; then log "Would remove $description: $path"; return 0; fi
	rm -rf -- "$path"
	log "Removed $description: $path"
}

is_owned_path() {
	local path="$1"
	[ -f "$owned_paths_file" ] || return 1
	grep -Fqx -- "$path" "$owned_paths_file"
}

remove_owned_path() {
	local path="$1" description="$2"
	if is_owned_path "$path"; then
		remove_path "$path" "$description"
	else
		[ -e "$path" ] || [ -L "$path" ] || return 0
		warn "Preserved $description (ownership not registered): $path"
	fi
}

is_owned_link() {
	local target="$1" resolved
	[[ -L "$target" ]] || return 1
	resolved="$(readlink -f "$target" 2>/dev/null || true)"
	[[ "$resolved" == "$SCRIPT_DIR"/* ]]
}

remove_stowed_links() {
	local source relative_path target
	while IFS= read -r -d '' source; do
		relative_path="${source#"$SCRIPT_DIR"/}"
		target="$HOME/$relative_path"
		if is_owned_link "$target"; then
			remove_path "$target" "dotfiles link"
		fi
	done < <(
		find "$SCRIPT_DIR" -mindepth 1 \
			-path "$SCRIPT_DIR/.git" -prune -o \
			-path "$SCRIPT_DIR/setup" -prune -o \
			-path "$SCRIPT_DIR/src" -prune -o \
			-path "$SCRIPT_DIR/bin" -prune -o \
			-name 'setup-*.sh' -prune -o \
			-name 'uninstall.sh' -prune -o \
			-name 'settings.yml' -prune -o \
			\( -type f -o -type d \) -print0
	)
}

remove_owned_tools() {
	local path manager package
	if [ -f "$owned_paths_file" ]; then
		while IFS= read -r path; do
			[ -n "$path" ] || continue
			remove_owned_path "$path" "user-installed terminal tool"
		done < "$owned_paths_file"
	fi

	[ -f "$owned_packages_file" ] || return 0
	if ! "$REMOVE_TOOLS"; then
		warn "System packages preserved. Use --tools to remove packages installed by this project."
		return 0
	fi
	while IFS=: read -r manager package; do
		[ -n "$manager" ] && [ -n "$package" ] || continue
		case "$package" in git|curl|zsh|stow) warn "Protected system package: $package"; continue ;; esac
		if "$DRY_RUN"; then
			log "Would remove package $manager:$package"
			continue
		fi
		case "$manager" in
			pkg) pkg uninstall -y "$package" ;;
			brew) brew uninstall "$package" ;;
			apt) sudo apt-get remove -y "$package" ;;
			dnf) sudo dnf remove -y "$package" ;;
			yum) sudo yum remove -y "$package" ;;
			pacman) sudo pacman -R --noconfirm "$package" ;;
			zypper) sudo zypper --non-interactive remove "$package" ;;
			apk) sudo apk del "$package" ;;
			*) warn "Unsupported package manager; preserved $manager:$package"; continue ;;
		esac
		log "Removed package $manager:$package"
	done < "$owned_packages_file"
}

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
