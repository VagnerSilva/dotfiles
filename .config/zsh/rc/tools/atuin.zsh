# atuin: shell history integration.
if command -v atuin >/dev/null 2>&1; then
	_atuin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/atuin_init.zsh"
	if [ ! -s "$_atuin_cache" ] || [ "$(command -v atuin)" -nt "$_atuin_cache" ]; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		atuin init zsh > "$_atuin_cache"
	fi
	[ -f "$_atuin_cache" ] && source "$_atuin_cache"
	unset _atuin_cache
fi
