# fnm: Node version manager shell environment.
_fnm_bin=""
if { [ -n "${TERMUX_VERSION:-}" ] || [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ]; } \
	&& [ -x "${XDG_DATA_HOME:-$HOME/.local/share}/fnm/fnm" ]; then
	_fnm_bin="${XDG_DATA_HOME:-$HOME/.local/share}/fnm/fnm"
	export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/fnm:$PATH"
else
	_fnm_bin="$(command -v fnm 2>/dev/null || true)"
fi
if [ -n "$_fnm_bin" ] && "$_fnm_bin" --version >/dev/null 2>&1; then
	_fnm_env_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/fnm_env.zsh"
	if [ ! -s "$_fnm_env_cache" ] || [ "$_fnm_bin" -nt "$_fnm_env_cache" ]; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		"$_fnm_bin" env --shell zsh > "$_fnm_env_cache"
	fi
	[ -f "$_fnm_env_cache" ] && source "$_fnm_env_cache"
fi
unset _fnm_bin _fnm_env_cache
