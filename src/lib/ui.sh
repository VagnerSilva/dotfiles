#!/usr/bin/env bash

# UI helpers for the dotfiles CLI.
# Colors are enabled only on a TTY and disabled by NO_COLOR.

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	C_BOLD=$'\033[1m'
	C_GREEN=$'\033[32m'
	C_YELLOW=$'\033[33m'
	C_RED=$'\033[31m'
	C_DIM=$'\033[2m'
	C_RESET=$'\033[0m'
else
	C_BOLD=''
	C_GREEN=''
	C_YELLOW=''
	C_RED=''
	C_DIM=''
	C_RESET=''
fi

mark_ok()   { printf '%s' "${C_GREEN}[ok]${C_RESET}"; }
mark_skip() { printf '%s' "${C_YELLOW}[skip]${C_RESET}"; }

ui_info()   { printf '%s\n' "${C_DIM}[INFO]${C_RESET} $*"; }
ui_ok()     { printf '%s\n' "$(mark_ok) $*"; }
ui_skip()   { printf '%s\n' "$(mark_skip) $*"; }
ui_warn()   { printf '%s\n' "${C_YELLOW}[WARN]${C_RESET} $*" >&2; }
ui_error()  { printf '%s\n' "${C_RED}[ERROR]${C_RESET} $*" >&2; }
ui_title()  { printf '\n%s\n' "${C_BOLD}### $* ###${C_RESET}"; }
ui_step()   { printf '\n%s\n' "${C_BOLD}>> $*${C_RESET}"; }
ui_result() { printf '  %s %-22s %s\n' "$1" "$2" "$3"; }
