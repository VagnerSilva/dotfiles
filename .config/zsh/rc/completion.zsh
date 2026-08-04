# RC: Completion
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Configures Zsh completion system.
#
# RESPONSIBILITIES
#   ✔ zstyle completion settings
#   ✔ completion behavior and caching
#   ✔ completion-related tweaks
#   ✔ asdf completion generation
#   ✔ compinit
#
# RULE OF THUMB
#   "Does this affect tab-completion behavior?"
#     → YES → belongs here
#
# LOADED FROM
#   .zshrc
# }}

zstyle ':completion:*' menu select	# Visualize and selecting with arrow keys in completion.
# Completion functions to try in given order. Ref: https://zsh.sourceforge.io/Doc/Release/Completion-System.html
zstyle ':completion:*' completer _expand _expand_alias _extensions _complete _ignored _correct _approximate
# Workaround for https://github.com/mollifier/cd-bookmark/issues/9
#zstyle ':completion:*:*:cd-bookmark:*' menu no

# Completion functions settings.
# _correct max errors for match (but not for numbers)
zstyle ':completion:*:correct:::' max-errors 2 not-numeric
# _approximate max errors for match
zstyle ':completion:*:approximate:::' max-errors 3 numeric
# Remove slash from completed directory.
zstyle ':completion:*' squeeze-slashes true
# Cache completions.
zstyle ':completion:*' use-cache on
# Use cache from XDG location
zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache
# Honor LS_COLORs in completion. Ref: https://github.com/ohmyzsh/ohmyzsh/issues/6060#issuecomment-1016734641
zstyle ':completion:*' list-colors "$LS_COLORS"
# Ignore case in tab complete. http://www.rlazo.org/2010/11/18/zsh-case-insensitive-completion/
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Completing process IDs with menu selection:
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
# Style if no matching completion is found.
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
# Refresh tab completion from PATH automatically, so hash(1) does not need to be called after installing a new program.
zstyle ':completion:*' rehash true

# Turn off URL completions for the open(1) command, like "file: ftp:// gopher:// http:// https://"
# Ref: https://github.com/mpv-player/mpv/issues/2892#issuecomment-190910887
# Ref: https://unix.stackexchange.com/a/567805/19909
zstyle ':completion:*:*:open:*' tag-order '!urls'
#zstyle ':completion:*:open:argument*' tag-order - '! urls'

# Use colors in tabcompletion. NOTE seems to work without this.
#shell_is_macos && zstyle ':completion:*:default' list-colors ''

# Increase maximum from default 100 suggestions to complete before asking to show more.
# No export: zsh-internal variable, not needed by child processes.
LISTMAX=500

# Complete options for aliases too.
setopt completealiases

# To force-regenerate the dump file: rm ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION

# Add tab completion to daemonize.
if command -v daemonize >/dev/null 2>&1; then
	compctl -cf daemonize
fi

# Generate asdf completions and add to fpath
# The generated file is cached; delete it to regenerate after an asdf upgrade.
# if (( $+commands[asdf] )); then
# 	_asdf_comp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions/_asdf"
# 	if [[ ! -f "$_asdf_comp" ]]; then
# 		mkdir -p "${_asdf_comp:h}"
# 		asdf completion zsh >| "$_asdf_comp"
# 	fi
# 	fpath=("${_asdf_comp:h}" $fpath)
# 	unset _asdf_comp
# fi

# Initialize the completion system.
# -d: XDG-compliant dump file location.
# -i: skip insecure directory check (safe for single-user setups)
# -C: skip the security check AND skip regenerating the dump — use when dump is fresh.
# zinit cdreplay: replays compdef calls queued by plugins loaded before compinit.
#
# Performance: only do a full fpath scan when the dump is older than 24 h.
# Within that window, use -C to skip both the security check and fpath rescan.
# After loading, background-compile the dump to a .zwc so future loads are faster.
autoload -Uz compinit
typeset _zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
# Never source a compiled completion dump. On WSL, a stale or partially-written
# `.zwc` can make a background Zsh job terminate with Bus Error.
rm -f "${_zcompdump}.zwc"
# Fast path (-C, skips compaudit) only when dump exists AND is <24 h old.
# Regenerate dump if missing or stale (>24h old).
if [ -f "$_zcompdump" ] && [ "$_zcompdump" -nt /dev/null ]; then
	compinit -C -d "$_zcompdump" -i    # dump fresh: skip rescan
else
	compinit -d "$_zcompdump" -i       # dump missing or stale: full rescan
fi
unset _zcompdump

# Replay queued compdefs only when zinit is available.
if type zinit >/dev/null 2>&1; then
	zinit cdreplay -q
fi

# Completion for functions
# For functions in $ZSH_CONFIG_DIR/functions/

# Complete files on $PATH
if command -v viw >/dev/null 2>&1; then
	compdef _command_names viw 2>/dev/null || true
fi
if command -v cdw >/dev/null 2>&1; then
	compdef _command_names cdw 2>/dev/null || true
fi