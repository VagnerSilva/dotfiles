# zoxide: smart directory jumper.
_zoxide_bin="$(command -v zoxide 2>/dev/null || true)"
if [ -n "$_zoxide_bin" ] && [ -x "$_zoxide_bin" ]; then
	eval "$("$_zoxide_bin" init zsh)"
fi
