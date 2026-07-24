# Lightweight terminal-startup diagnostics. Enabled by setup-zinit.sh while
# investigating the intermittent Bus Error. It must never enable `xtrace`:
# Zsh writes xtrace to the terminal, which interferes with ZLE and fzf-tab.

_zsh_debug_flag="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/features/bus-error-debug.enabled"

if [[ $- == *i* ]] && [[ -f "$_zsh_debug_flag" ]] && [[ -z "${_ZSH_STARTUP_DEBUG_ACTIVE:-}" ]]; then
	typeset -g _ZSH_STARTUP_DEBUG_ACTIVE=1
	typeset -g _ZSH_STARTUP_DEBUG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/debug"
	mkdir -p "$_ZSH_STARTUP_DEBUG_DIR"
	typeset -g _ZSH_STARTUP_DEBUG_LOG="$_ZSH_STARTUP_DEBUG_DIR/startup-${$}-${RANDOM}.log"
	print -r -- "started_at=$(date --iso-8601=seconds) pid=$$ ppid=$PPID zdotdir=${ZDOTDIR:-$HOME/.config/zsh}" > "$_ZSH_STARTUP_DEBUG_LOG"

	# A background Zsh job that dies from SIGBUS reports status 149 (128 + 21).
	# Keep the report on disk so it survives terminal redraws and job notifications.
	TRAPCHLD() {
		local child_status=$?
		if (( child_status == 149 )); then
			print -r -- "SIGBUS observed_at=$(date --iso-8601=seconds) shell_pid=$$ child_status=$child_status" >> "$_ZSH_STARTUP_DEBUG_LOG"
			jobs -l >> "$_ZSH_STARTUP_DEBUG_LOG" 2>&1
		fi
		return 0
	}
fi

unset _zsh_debug_flag