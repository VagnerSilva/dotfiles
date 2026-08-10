local script_dir cli_target
local -a completed=()

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=../setup/common.sh
source "$script_dir/setup/common.sh"

cli_target="$HOME/.local/bin/dotfiles"

run_step() {
	local title="$1" path="$2"
	ui_step "$title"
	if bash "$path"; then
		ui_ok "$title"
		completed+=("$title")
	else
		ui_error "$title failed. Fix the issue and run 'dotfiles install' again."
		return 1
	fi
}

ui_title "Install: dotfiles environment"
ui_info "This installer will guide you through 5 steps. Each step asks for"
ui_info "confirmation before making any change."
printf '\n'
ui_result "" "Step 1" "zsh, stow, login shell and dotfile links"
ui_result "" "Step 2" "CLI tools: packages, starship, fnm, sdkman"
ui_result "" "Step 3" "Zinit plugin manager"
ui_result "" "Step 4" "Nerd Font and terminal configuration"
ui_result "" "Step 5" "install the dotfiles CLI on PATH (optional)"
printf '\n'

run_step "Step 1/5 - zsh setup" "$script_dir/setup-zsh.sh" || return 1
run_step "Step 2/5 - tools setup" "$script_dir/setup/tools.sh" || return 1
run_step "Step 3/5 - zinit setup" "$script_dir/setup-zinit.sh" || return 1
run_step "Step 4/5 - Nerd Font setup" "$script_dir/setup-nerd-font.sh" || return 1

ui_step "Step 5/5 - dotfiles CLI on PATH (optional)"
if confirm_step "Install the dotfiles CLI on PATH (~/.local/bin/dotfiles)?"; then
	if [ -e "$cli_target" ] && [ ! -L "$cli_target" ]; then
		ui_warn "$cli_target exists as a regular file; left untouched."
	else
		mkdir -p "$(dirname "$cli_target")"
		ln -sfn "$script_dir/bin/dotfiles" "$cli_target"
		record_owned_path "$cli_target"
		ui_ok "dotfiles CLI installed at $cli_target"
		completed+=("Step 5 - dotfiles CLI on PATH")
		if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
			ui_warn "$HOME/.local/bin is not on PATH; add it to use the 'dotfiles' command."
		fi
	fi
else
	ui_skip "dotfiles CLI step skipped."
fi

printf '\nSummary:\n'
for step in "${completed[@]}"; do
	ui_result "$(mark_ok)" "$step" "completed"
done
ui_info "Open a new zsh session to apply all changes."
