# mise: runtime shims and shell hooks.
_mise_bin="$(command -v mise 2>/dev/null || true)"
if [ -n "$_mise_bin" ] && [ -x "$_mise_bin" ]; then
	_mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/mise_activate.zsh"
	if [ ! -s "$_mise_cache" ]; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		mise activate zsh > "$_mise_cache"
	fi
	[ -f "$_mise_cache" ] && source "$_mise_cache"
	unset _mise_cache
fi
