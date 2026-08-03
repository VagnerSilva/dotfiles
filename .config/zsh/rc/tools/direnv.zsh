# direnv: per-directory environment hook.
if command -v direnv >/dev/null 2>&1; then
	_direnv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/direnv_hook.zsh"
	if [ ! -s "$_direnv_cache" ]; then
		direnv hook zsh > "$_direnv_cache"
	fi
	[ -f "$_direnv_cache" ] && source "$_direnv_cache"
	unset _direnv_cache
fi
