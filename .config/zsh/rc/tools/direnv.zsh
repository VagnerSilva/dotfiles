# direnv: per-directory environment hook.
_direnv_bin="$(command -v direnv 2>/dev/null || true)"
if [ -n "$_direnv_bin" ] && [ -x "$_direnv_bin" ]; then
	_direnv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/direnv_hook.zsh"
	if [ ! -s "$_direnv_cache" ]; then
		direnv hook zsh > "$_direnv_cache"
	fi
	[ -f "$_direnv_cache" ] && source "$_direnv_cache"
	unset _direnv_cache
fi
