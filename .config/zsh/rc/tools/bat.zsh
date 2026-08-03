# bat: pager and man-page styling.
export BAT_THEME="Solarized (light)"
_batman_bin="$(command -v batman 2>/dev/null || true)"
if [ -n "$_batman_bin" ] && [ -x "$_batman_bin" ]; then
	_batman_env_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/batman_env.zsh"
	if [ ! -s "$_batman_env_cache" ]; then
		batman --export-env > "$_batman_env_cache"
	fi
	[ -f "$_batman_env_cache" ] && source "$_batman_env_cache"
	unset _batman_env_cache
fi
