# bat: pager and man-page styling.
export BAT_THEME="Solarized (light)"
if command -v batman >/dev/null 2>&1; then
	_batman_env_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/batman_env.zsh"
	if [ ! -s "$_batman_env_cache" ]; then
		batman --export-env > "$_batman_env_cache"
	fi
	[ -f "$_batman_env_cache" ] && source "$_batman_env_cache"
	unset _batman_env_cache
fi
