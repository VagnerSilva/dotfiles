# Environment: Interactive Tools
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Configures interactive CLI tools and enhancements.
#
# RESPONSIBILITIES
#   ✔ Tool integrations (configured here; installed via zinit or system package manager):
#     - starship (prompt init hook — managed here regardless of install method)
#     - fzf
#     - bat
#     - broot
#     - fzf-marks
#     - direnv
#
#   ✔ Interactive-only environment variables
#     (e.g. FZF_DEFAULT_COMMAND, GPG_TTY)
#
# IMPORTANT
#   These tools:
#     - enhance interactive usage
#     - are NOT required for scripts
#
# RULE OF THUMB
#   "Is this only useful when I am actively using the shell?"
#     → YES → belongs here
#
# LOADED FROM
#   .zshrc
# }}

# GPG_TTY — needed for gpg(1) to work in interactive shells (e.g. git commit signing).
# $TTY is a zsh builtin (no subprocess needed, unlike $(tty)).
# Set here rather than env/programs.zsh: only meaningful for interactive shells with a TTY.
# (( $+commands[gpg] )) && export GPG_TTY=$TTY

# fnm — Node version manager environment.
if command -v fnm >/dev/null 2>&1; then
	_fnm_env_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/fnm_env.zsh"
	if [ ! -s "$_fnm_env_cache" ] || [ "$(command -v fnm)" -nt "$_fnm_env_cache" ] 2>/dev/null; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		fnm env --shell zsh > "$_fnm_env_cache"
	fi
	if [ -f "$_fnm_env_cache" ]; then
		source "$_fnm_env_cache"
	fi
	unset _fnm_env_cache
fi

# mise — interactive shell integration for runtime shims and hooks.
if command -v mise >/dev/null 2>&1; then
	_mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/mise_activate.zsh"
	if [ ! -s "$_mise_cache" ]; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		mise activate zsh > "$_mise_cache"
	fi
	if [ -f "$_mise_cache" ]; then
		source "$_mise_cache"
	fi
	unset _mise_cache
fi

# Apply a preset selected during setup-zinit when Starship was not yet available.
_starship_preset_file="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/starship-preset"
_starship_config_file="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
if command -v starship >/dev/null 2>&1 && [ -s "$_starship_preset_file" ]; then
	read -r _starship_preset < "$_starship_preset_file"
	if starship preset "$_starship_preset" --output "$_starship_config_file" --force >/dev/null 2>&1; then
		rm -f -- "$_starship_preset_file"
	fi
fi
unset _starship_preset _starship_preset_file _starship_config_file

# starship — cross-shell prompt. Do not execute a binary previously downloaded
# by Zinit: a broken release asset can terminate the startup job with SIGBUS.
_starship_bin="$(command -v starship 2>/dev/null || true)"
if [ -z "$_starship_bin" ] && [ -x "$HOME/.local/bin/starship" ]; then
	_starship_bin="$HOME/.local/bin/starship"
fi
case "$_starship_bin" in
	"$HOME/.local/share/zinit/"*) _starship_bin="" ;;
esac
if [ -n "$_starship_bin" ]; then
	_starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/starship_init.zsh"
	if [ ! -s "$_starship_cache" ] || [ "$_starship_bin" -nt "$_starship_cache" ]; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		"$_starship_bin" init zsh > "$_starship_cache"
	fi
	if [ -f "$_starship_cache" ]; then
		source "$_starship_cache"
	fi
	unset _starship_bin _starship_cache
fi

# bat / batman — interactive pager and man-page styling.
export BAT_THEME="Solarized (light)" # Works for dark mode as well.
if command -v batman >/dev/null 2>&1; then
	_batman_env_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/batman_env.zsh"
	if [ ! -s "$_batman_env_cache" ]; then
		batman --export-env > "$_batman_env_cache"
	fi
	if [ -f "$_batman_env_cache" ]; then
		source "$_batman_env_cache"
	fi
	unset _batman_env_cache
fi

# broot - https://dystroy.org/broot/install-br/
if command -v broot >/dev/null 2>&1; then
	br() {
		local cmd cmd_file code
		cmd_file=$(mktemp)
		if broot --outcmd "$cmd_file" "$@"; then
			cmd=$(cat "$cmd_file")
			command rm -f "$cmd_file"
			eval "$cmd"
		else
			code=$?
			command rm -f "$cmd_file"
			return "$code"
		fi
	}
fi

# fzf — binary installed via zinit (see zinit.zsh). https://github.com/junegunn/fzf
if command -v fzf >/dev/null 2>&1; then
	fzf_init_file="${XDG_CACHE_HOME:-$HOME/.cache}/fzf.zsh"
	if [ ! -s "$fzf_init_file" ]; then
		if fzf --zsh > "$fzf_init_file" 2>/dev/null; then
			:
		else
			touch "$fzf_init_file"
			# Fallback for older distro packages that do not support `fzf --zsh`.
			if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
				cat /usr/share/doc/fzf/examples/key-bindings.zsh >> "$fzf_init_file"
			fi
			if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
				cat /usr/share/doc/fzf/examples/completion.zsh >> "$fzf_init_file"
			fi
		fi
	fi
	if [ -s "$fzf_init_file" ]; then
		source "$fzf_init_file"
	fi
	unset fzf_init_file

	# Default cli options. See fzf(1)
	export FZF_COMPLETION_OPTS='--multi'

	# Find dot files as well. Reference: https://github.com/junegunn/fzf/issues/634
	if command -v fd >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fd --type file --hidden --follow'
	elif command -v fdfind >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fdfind --type file --hidden --follow'
	else
		export FZF_DEFAULT_COMMAND='find . -type d \( -path './.git' -o -path './node_modules'  \) -prune -o -print'
	fi
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_DEFAULT_COMMAND="$FZF_DEFAULT_COMMAND --exclude '.git/'"
fi


# direnv — binary installed via zinit (see zinit.zsh). https://direnv.net/
if command -v direnv >/dev/null 2>&1; then
	_direnv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/direnv_hook.zsh"
	if [ ! -s "$_direnv_cache" ]; then
		direnv hook zsh > "$_direnv_cache"
	fi
	if [ -f "$_direnv_cache" ]; then
		source "$_direnv_cache"
	fi
	unset _direnv_cache
fi

# cd-bookmark. Aliases in $ZDOTDIR/rc/aliases.zsh
#if [ -d ~/.local/repos/cd-bookmark ]; then
#    #fpath=(~/src/github.com/erikw/cd-bookmark/(N-/) $fpath)
#    fpath=(~/.local/repos/cd-bookmark(N-/) $fpath)
#    autoload -Uz cd-bookmark
#fi

# fzf-marks: https://github.com/urbainvaes/fzf-marks
_fzf_marks_plugin="${ZINIT[PLUGINS_DIR]}/urbainvaes---fzf-marks/fzf-marks.plugin.zsh"
if [ -f "$_fzf_marks_plugin" ]; then
	FZF_MARKS_COMMAND="fzf --exact --select-1 --nth=1 --delimiter=' : '"
	FZF_MARKS_DELETE=ctrl-r
	source "$_fzf_marks_plugin"
fi
unset _fzf_marks_plugin

# qlty. From $(curl https://qlty.sh | sh)
if [ -d "$HOME/.qlty" ]; then
	export QLTY_INSTALL="$HOME/.qlty"
	export PATH="$QLTY_INSTALL/bin:$PATH"
	[ -s "/usr/local/share/zsh/site-functions/_qlty" ] && source "/usr/local/share/zsh/site-functions/_qlty"
fi