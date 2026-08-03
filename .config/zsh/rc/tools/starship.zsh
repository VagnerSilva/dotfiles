# starship: prompt initialization.
_starship_preset_file="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/starship-preset"
_starship_config_file="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
if command -v starship >/dev/null 2>&1 && [ -s "$_starship_preset_file" ]; then
	read -r _starship_preset < "$_starship_preset_file"
	if starship preset "$_starship_preset" --output "$_starship_config_file" --force >/dev/null 2>&1; then
		rm -f -- "$_starship_preset_file"
	fi
fi
unset _starship_preset _starship_preset_file _starship_config_file

_starship_bin="$(command -v starship 2>/dev/null || true)"
if [ -n "$_starship_bin" ] && [ ! -x "$_starship_bin" ]; then
	_starship_bin=""
fi
case "$_starship_bin" in
	"$HOME/.local/share/zinit/"*|"$HOME/.local/shared/zinit/"*) _starship_bin="" ;;
esac
if [ -n "$_starship_bin" ]; then
	_starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/starship_init.zsh"
	if [ ! -s "$_starship_cache" ] || [ "$_starship_bin" -nt "$_starship_cache" ]; then
		mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
		"$_starship_bin" init zsh > "$_starship_cache"
	fi
	[ -f "$_starship_cache" ] && source "$_starship_cache"
fi
unset _starship_bin _starship_cache
