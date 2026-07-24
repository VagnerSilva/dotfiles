# Optional startup-only xtrace recorder for diagnosing terminal initialization.
# Enabled by setup-zinit.sh while investigating the intermittent Bus Error.

_zsh_debug_flag="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/features/bus-error-debug.enabled"

if [[ $- == *i* ]] && [[ -f "$_zsh_debug_flag" ]] && [[ -z "${_ZSH_STARTUP_DEBUG_ACTIVE:-}" ]]; then
	# XTRACEFD is only recognized by Zsh when inherited at process startup. Re-exec
	# normal interactive terminals once with descriptor 3 and tracing configured.
	# Skip `zsh -c` so scripts retain their requested command semantics.
	if [[ -z "${_ZSH_STARTUP_DEBUG_REEXEC:-}" ]] && [[ -z "${XTRACEFD:-}" ]] && [[ -z "${ZSH_EXECUTION_STRING:-}" ]]; then
		typeset -g _ZSH_STARTUP_DEBUG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/debug"
		mkdir -p "$_ZSH_STARTUP_DEBUG_DIR"
		export ZSH_STARTUP_DEBUG_LOG="$_ZSH_STARTUP_DEBUG_DIR/startup-${$}-${RANDOM}.xtrace"
		exec 3>> "$ZSH_STARTUP_DEBUG_LOG"
		export XTRACEFD=3
		export PS4='+%D{%Y-%m-%dT%H:%M:%S} pid=%_ %N:%i> '
		export _ZSH_STARTUP_DEBUG_REEXEC=1

		if [[ -o login ]]; then
			exec zsh -il
		else
			exec zsh -i
		fi
	fi

	# The re-executed terminal has a working XTRACEFD and shares descriptor 3.
	if [[ -n "${XTRACEFD:-}" ]] && [[ -n "${ZSH_STARTUP_DEBUG_LOG:-}" ]]; then
		typeset -g _ZSH_STARTUP_DEBUG_ACTIVE=1
		print -r -- "startup pid=$$ ppid=$PPID zdotdir=${ZDOTDIR:-$HOME/.config/zsh}" >&$XTRACEFD
	else
		unset _zsh_debug_flag
		return 0
	fi

	setopt xtrace

	# Stop tracing the foreground shell at the first prompt. Any startup child
	# already spawned inherits xtrace and retains its PID in the same log.
	_zsh_stop_startup_debug_trace() {
		print -r -- "startup trace complete pid=$$" >&$XTRACEFD
		setopt noxtrace
		autoload -Uz add-zsh-hook
		add-zsh-hook -d precmd _zsh_stop_startup_debug_trace
	}
	autoload -Uz add-zsh-hook
	add-zsh-hook precmd _zsh_stop_startup_debug_trace
fi

unset _zsh_debug_flag