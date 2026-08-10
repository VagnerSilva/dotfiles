# eza: modern, git-aware ls replacement.
# The theme is read automatically from $XDG_CONFIG_HOME/eza/theme.yml
# (linked by stow from this repo's .config/eza/theme.yml).
_eza_bin="$(command -v eza 2>/dev/null || true)"
if [ -n "$_eza_bin" ] && [ -x "$_eza_bin" ]; then
	alias ls='eza'
	alias ll='eza -l --git --icons'
	alias la='eza -a'
	alias lt='eza --tree --level=2'
fi
unset _eza_bin
