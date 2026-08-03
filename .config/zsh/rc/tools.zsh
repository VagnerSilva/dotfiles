# RC: Interactive tool integrations
#
# This file only dispatches configuration modules. It never installs packages,
# downloads files, or updates tools.

for tool_config in "$ZDOTDIR/rc/tools/"*.zsh(N); do
	[ -r "$tool_config" ] || continue
	source "$tool_config"
done
