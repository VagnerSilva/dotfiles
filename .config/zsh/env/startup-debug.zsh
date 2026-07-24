# Optional startup-only xtrace recorder for diagnosing terminal initialization.
# Enabled by setup-zinit.sh while investigating the intermittent Bus Error.

_zsh_debug_flag="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/features/bus-error-debug.enabled"

if [[ $- == *i* ]] && [[ -f "$_zsh_debug_flag" ]] && [[ -z "${_ZSH_STARTUP_DEBUG_ACTIVE:-}" ]]; then
	typeset -g _ZSH_STARTUP_DEBUG_ACTIVE=1
	typeset -g _ZSH_STARTUP_DEBUG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/debug"
	mkdir -p "$_ZSH_STARTUP_DEBUG_DIR"
	typeset -g _ZSH_STARTUP_DEBUG_LOG="$_ZSH_STARTUP_DEBUG_DIR/startup-${$}-${RANDOM}.xtrace"

	exec {ZSH_STARTUP_DEBUG_FD}>> "$_ZSH_STARTUP_DEBUG_LOG"
	typeset -gi XTRACEFD=$ZSH_STARTUP_DEBUG_FD
	PS4='+%D{%Y-%m-%dT%H:%M:%S} pid=$$ %N:%i> '
	print -r -- "startup pid=$$ ppid=$PPID zdotdir=${ZDOTDIR:-$HOME/.config/zsh}" >&$ZSH_STARTUP_DEBUG_FD
	setopt xtrace

	# Stop tracing the foreground shell at the first prompt. Any startup child
	# already spawned inherits xtrace and retains its PID in the same log.
	_zsh_stop_startup_debug_trace() {
		print -r -- "startup trace complete pid=$$" >&$ZSH_STARTUP_DEBUG_FD
		setopt noxtrace
		autoload -Uz add-zsh-hook
		add-zsh-hook -d precmd _zsh_stop_startup_debug_trace
	}
	autoload -Uz add-zsh-hook
	add-zsh-hook precmd _zsh_stop_startup_debug_trace
fi

unset _zsh_debug_flag