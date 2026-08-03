# broot: directory navigation helper.
if command -v broot >/dev/null 2>&1; then
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
