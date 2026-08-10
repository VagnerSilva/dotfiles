local script_dir xdg_config xdg_data xdg_state zinit_home zsh_path
local login_shell="" verbose="${args[--verbose]:-}"
local pending=0 total=0

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=../setup/common.sh
source "$script_dir/setup/common.sh"

xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
xdg_state="${XDG_STATE_HOME:-$HOME/.local/state}"
zinit_home="${ZINIT_HOME:-$HOME/.local/repos/zinit}"
zsh_path="$(command -v zsh 2>/dev/null || true)"

check_category() { printf '\n%s\n' "${C_BOLD}$1${C_RESET}"; }

check_status() {
	local label="$1" ok="$2" hint="$3" detail="${4:-}"
	total=$((total + 1))
	if [ "$ok" = 1 ]; then
		if [ -n "$verbose" ] && [ -n "$detail" ]; then
			ui_result "$(mark_ok)" "$label" "$detail"
		else
			ui_result "$(mark_ok)" "$label" "ready"
		fi
	else
		pending=$((pending + 1))
		ui_result "$(mark_skip)" "$label" "$hint"
	fi
}

ui_title "Check: dotfiles environment"

check_category "Prerequisites"
check_status "zsh" "$([ -n "$zsh_path" ] && echo 1 || echo 0)" "missing: run dotfiles install" "$zsh_path"
check_status "stow" "$(is_command_available stow && echo 1 || echo 0)" "missing: install stow via the package manager"
check_status "curl" "$(is_command_available curl && echo 1 || echo 0)" "missing: needed for font and tool downloads"
check_status "git" "$(is_command_available git && echo 1 || echo 0)" "missing: needed for zinit"
check_status "package manager" "$([ -n "$(detect_package_manager)" ] && echo 1 || echo 0)" "none detected: install zsh and stow manually"

check_category "Dotfiles links"
check_status ".zshenv" "$([ -L "$HOME/.zshenv" ] && [ "$(readlink -f "$HOME/.zshenv" 2>/dev/null || true)" = "$script_dir/.zshenv" ] && echo 1 || echo 0)" "not linked to this repository" "$HOME/.zshenv"
check_status ".config/zsh/.zshenv" "$([ -L "$xdg_config/zsh/.zshenv" ] && [ "$(readlink -f "$xdg_config/zsh/.zshenv" 2>/dev/null || true)" = "$script_dir/.config/zsh/.zshenv" ] && echo 1 || echo 0)" "not linked to this repository" "$xdg_config/zsh/.zshenv"

check_category "Tools"
check_status "starship" "$({ is_command_available starship || [ -x "$HOME/.local/bin/starship" ]; } && echo 1 || echo 0)" "missing: run dotfiles install"
check_status "fnm" "$({ is_command_available fnm || [ -x "$xdg_data/fnm/fnm" ]; } && echo 1 || echo 0)" "missing: run dotfiles install"
check_status "sdkman" "$([ -f "$HOME/.sdkman/bin/sdkman-init.sh" ] && echo 1 || echo 0)" "missing: run dotfiles install"
check_status "atuin" "$(is_command_available atuin && echo 1 || echo 0)" "missing: run dotfiles install"
check_status "zinit" "$([ -f "$zinit_home/zinit.zsh" ] && echo 1 || echo 0)" "missing: run dotfiles install" "$zinit_home/zinit.zsh"

check_category "Extras"
check_status "Nerd Font (Meslo)" "$([ -f "$xdg_data/fonts/NerdFonts/Meslo/MesloLGSNerdFont-Regular.ttf" ] && echo 1 || echo 0)" "missing: run dotfiles install"
check_status "ownership state" "$([ -d "$xdg_state/dotfiles" ] && echo 1 || echo 0)" "not found: nothing was installed yet" "$xdg_state/dotfiles"

check_category "Shell"
if is_command_available getent; then
	login_shell="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | cut -d: -f7 || true)"
fi
login_shell="${login_shell:-${SHELL:-}}"
if [ -z "$zsh_path" ]; then
	check_status "login shell" 0 "install zsh first" "${login_shell:-unknown}"
elif [ -n "$login_shell" ] && [ "$login_shell" = "$zsh_path" ]; then
	check_status "login shell" 1 "" "$login_shell"
else
	check_status "login shell" 0 "expected $zsh_path, found ${login_shell:-unknown}" "$login_shell"
fi

printf '\n'
if [ "$pending" -eq 0 ]; then
	ui_ok "All $total checks passed."
	return 0
fi
ui_warn "$pending of $total checks failed."
ui_info "Run \`dotfiles install\` to set up the missing pieces."
return 1
