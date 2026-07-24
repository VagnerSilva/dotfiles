#!/usr/bin/env bash

# Launch a traced interactive Zsh session and retain enough evidence to identify
# the process that receives SIGBUS. Exit the traced shell with `exit` after the
# error occurs, then inspect the printed report.

set -euo pipefail

if ! command -v zsh >/dev/null 2>&1; then
  printf '[ERROR] zsh is not installed.\n' >&2
  exit 1
fi

if ! command -v strace >/dev/null 2>&1; then
  printf '[ERROR] strace is required to capture SIGBUS. Install it and retry.\n' >&2
  exit 1
fi

umask 077

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/debug"
timestamp="$(date +%Y%m%dT%H%M%S)"
log_dir="$state_dir/startup-$timestamp-$$"
mkdir -p "$log_dir"

trace_prefix="$log_dir/strace"
metadata_log="$log_dir/metadata.txt"

{
  printf 'started_at=%s\n' "$(date --iso-8601=seconds)"
  printf 'zsh=%s\n' "$(command -v zsh)"
  zsh --version
  printf 'ZDOTDIR=%s\n' "${ZDOTDIR:-$HOME/.config/zsh}"
  printf 'PWD=%s\n' "$PWD"
} > "$metadata_log"

printf 'Starting traced Zsh session. Reproduce the Bus Error, then run exit.\n'
printf 'Logs: %s\n\n' "$log_dir"

set +e
strace -ff -tt -s 256 -o "$trace_prefix" -e trace=process,signal,file -- \
  zsh -il
zsh_exit_code=$?
set -e

printf '\nzsh_exit_code=%s\n' "$zsh_exit_code" >> "$metadata_log"

printf '\n=== SIGBUS report ===\n'
if grep -Hn -C 12 'SIGBUS' "$log_dir"/strace*; then
  printf '\nSIGBUS captured. The matching strace.<pid> file contains the process command.\n'
  printf 'The same strace.<pid> file shows the executed process and loaded files.\n'
else
  printf 'No SIGBUS was captured in this session. Keep this directory and retry if needed.\n'
fi

printf '\nArtifacts:\n'
printf '  metadata: %s\n' "$metadata_log"
printf '  system traces: %s.*\n' "$trace_prefix"