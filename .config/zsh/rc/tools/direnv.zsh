# direnv: per-directory environment hook.
_direnv_bin="$(command -v direnv 2>/dev/null || true)"
if [ -n "$_direnv_bin" ] && [ -x "$_direnv_bin" ]; then
	_direnv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/direnv_hook.zsh"
	_direnv_cache_marker="# direnv-bin: $_direnv_bin"
	if [ ! -s "$_direnv_cache" ] || ! grep -Fqx -- "$_direnv_cache_marker" "$_direnv_cache" 2>/dev/null; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		{
			printf '%s\n' "$_direnv_cache_marker"
			"$_direnv_bin" hook zsh | sed 's| export zsh)"| export zsh 2>/dev/null)"|'
		} > "$_direnv_cache.tmp" && mv -- "$_direnv_cache.tmp" "$_direnv_cache"
	fi
	[ -f "$_direnv_cache" ] && source "$_direnv_cache"
	unset _direnv_cache _direnv_cache_marker
fi
unset _direnv_bin
