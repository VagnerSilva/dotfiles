local self target
self="$(readlink -f "${BASH_SOURCE[0]}")"
target="${other_args[0]:-}"
if [ -n "$target" ]; then
	"$self" "$target" --help
else
	"$self" --help
fi
