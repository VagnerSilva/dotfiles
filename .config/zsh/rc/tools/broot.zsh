# broot: directory navigation helper.
_broot_bin="$(command -v broot 2>/dev/null || true)"
if [ -n "$_broot_bin" ] && [ -x "$_broot_bin" ]; then
	br() {
		local cmd cmd_file code
		cmd_file=$(mktemp) || return 1
		if broot --outcmd "$cmd_file" "$@"; then
			cmd=$(cat "$cmd_file")
			command rm -f -- "$cmd_file"
			eval "$cmd"
		else
			code=$?
			command rm -f -- "$cmd_file"
			return "$code"
		fi
	}
fi
