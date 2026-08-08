# fzf: shell integration and defaults.
if command -v fzf >/dev/null 2>&1; then
	_fzf_init_file="${XDG_CACHE_HOME:-$HOME/.cache}/fzf.zsh"
	if [ ! -s "$_fzf_init_file" ]; then
		if ! fzf --zsh > "$_fzf_init_file" 2>/dev/null; then
			: > "$_fzf_init_file"
			[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && cat /usr/share/doc/fzf/examples/key-bindings.zsh >> "$_fzf_init_file"
			[ -f /usr/share/doc/fzf/examples/completion.zsh ] && cat /usr/share/doc/fzf/examples/completion.zsh >> "$_fzf_init_file"
		fi
	fi
	[ -s "$_fzf_init_file" ] && source "$_fzf_init_file"
	unset _fzf_init_file

	export FZF_COMPLETION_OPTS='--multi'
	if command -v fd >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fd --type file --hidden --follow'
	elif command -v fdfind >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fdfind --type file --hidden --follow'
	else
		export FZF_DEFAULT_COMMAND="find . -type d \( -path './.git' -o -path './node_modules' \) -prune -o -print"
	fi
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_DEFAULT_COMMAND="$FZF_DEFAULT_COMMAND --exclude '.git/'"
fi
