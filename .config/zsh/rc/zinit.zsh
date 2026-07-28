# RC: Zinit Plugin Manager

# PURPOSE
#   Bootstraps Zinit and loads all shell plugins.
#
# RESPONSIBILITIES
#   ✔ Source zinit from submodule at $HOME/.local/repos/zinit
#   ✔ Install binary tools from GitHub Releases as fallback (skipped if already on PATH)
#   ✔ Declare all shell plugins:
#       - binary/program plugins:  loaded eagerly only when not already installed
#       - ZLE/interactive plugins: loaded via Turbo mode (deferred to after first prompt — see comments in Plugins section)
#   ✔ Load env.local (secrets)
#
# NOTES
#   - compinit is called in rc/completion.zsh (after this file)
#   - Binary tools are fetched from GitHub Releases — no package manager needed.
#     Works on macOS, Linux, and devcontainers alike.
#   - To update all plugins and binaries: zinit update

# Secrets (gitignore'd!). Loaded here so they are available to all rc/* files that follow.
# [ -f "$ZDOTDIR/env.local" ] && source "$ZDOTDIR/env.local"

# Zinit bootstrap
ZINIT_HOME="$HOME/.local/repos/zinit"
if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
	echo "zinit not found at $ZINIT_HOME — run the install script" >&2
	return 1
fi
source "$ZINIT_HOME/zinit.zsh"

# GitHub-release binaries are only managed on architectures for which their
# upstream projects publish 64-bit assets. Zinit selects the matching release
# asset from the running host; unsupported hosts keep using system packages.
case "$(uname -m)" in
	x86_64|amd64|aarch64|arm64)
		ZINIT_MANAGED_RELEASES_SUPPORTED=1
		;;
	*)
		ZINIT_MANAGED_RELEASES_SUPPORTED=0
		print -u2 -- "zinit: skipping managed release binaries on unsupported architecture: $(uname -m)"
		;;
esac

# Plugins {{

# Binary tools {{
# Installed directly from GitHub Releases as a fallback.
# If the tool is already on PATH (e.g. via Homebrew on macOS or apt on Linux),
# zinit is skipped entirely — saving ~4ms of plugin-loading overhead per tool.
# On a fresh devcontainer where tools are absent, zinit installs them automatically.
# Run `zinit update` to update the zinit-managed copies.
#

# fzf — fuzzy finder. Shell integration configured in rc/tools.zsh.
if [ "$ZINIT_MANAGED_RELEASES_SUPPORTED" -eq 1 ] && ! command -v fzf >/dev/null 2>&1; then
	zinit ice from"gh-r" as"program" pick"fzf"
	zinit light junegunn/fzf
fi

# fd — fast alternative to find.
if [ "$ZINIT_MANAGED_RELEASES_SUPPORTED" -eq 1 ] && ! command -v fd >/dev/null 2>&1; then
	zinit ice from"gh-r" as"program" pick"**/fd"
	zinit light sharkdp/fd
fi

# bat — cat with syntax highlighting. Used as MANPAGER in rc/tools.zsh.
if [ "$ZINIT_MANAGED_RELEASES_SUPPORTED" -eq 1 ] && ! command -v bat >/dev/null 2>&1; then
	zinit ice from"gh-r" as"program" pick"**/bat"
	zinit light sharkdp/bat
fi

# ripgrep — fast grep alternative.
if [ "$ZINIT_MANAGED_RELEASES_SUPPORTED" -eq 1 ] && ! command -v rg >/dev/null 2>&1; then
	zinit ice from"gh-r" as"program" pick"**/rg"
	zinit light BurntSushi/ripgrep
fi

# direnv — per-directory env vars. Hook configured in rc/tools.zsh.
if [ "$ZINIT_MANAGED_RELEASES_SUPPORTED" -eq 1 ] && ! command -v direnv >/dev/null 2>&1; then
	zinit ice from"gh-r" as"program" extract"!" mv"direnv* -> direnv" pick"direnv"
	zinit light direnv/direnv
fi

# fnm — fast Node version manager.
[ "${ZINIT_MANAGED_RELEASES_SUPPORTED:-1}" -eq 1 ] && ! command -v fnm >/dev/null 2>&1; then
    zinit ice from"gh-r" as"program" sbin"fnm" \
        atclone"./fnm completions --shell zsh > _fnm" \
        atpull"%atclone" \
        as"completion"
    zinit light Schniz/fnm
fi

# cloc — count lines of code. Perl script, no compilation needed.
if ! command -v cloc >/dev/null 2>&1; then
	zinit ice as"program" pick"cloc"
	zinit light AlDanial/cloc
fi

# rename — Perl-based file renaming (compatible with Ubuntu's rename).
if ! command -v rename >/dev/null 2>&1; then
	zinit ice as"program" pick"rename"
	zinit light subogero/rename
fi

# dircolors-solarized — solarized color theme for ls/dircolors.
# Data files only; cloned for the dircolors.256dark file used in rc/ui.zsh.
zinit ice as"null"
zinit light seebi/dircolors-solarized

# tig — text-mode git UI. Requires compilation from source; not suitable for
# zinit binary install. Install via system package manager (brew/apt).

# lazygit — TUI git client. Ships pre-built binaries; works as zinit fallback.
# if (( ! $+commands[lazygit] )); then
#	zinit ice from"gh-r" as"program" pick"lazygit"
#	zinit light jesseduffield/lazygit
# fi

# fzf-marks — bookmark directories with fzf.
# Cloned here for zinit to manage updates, but NOT sourced yet.
# Must load after bindkey -v (rc/bindings.zsh), so it is sourced in rc/tools.zsh.
zinit ice pick"/dev/null" nocompile
zinit light urbainvaes/fzf-marks
# }}

# Shell plugins {{
# Extra completions — eager: must populate fpath before compinit (rc/completion.zsh).
# blockf: lets zinit control fpath injection timing.
zinit ice blockf lucid nocompile
zinit light zsh-users/zsh-completions

# Load ZLE plugins synchronously after compinit to avoid background startup jobs.
#
# This function is called by .zshrc after rc/completion.zsh. Keeping it here
# lets Zinit continue managing the plugins while ensuring fzf-tab sees an
# initialized completion system and syntax highlighting remains last.
load_zle_plugins() {
	# Inline suggestions (like fish). atload'!' activates the widget immediately.
	zinit ice lucid nocompile atload'!_zsh_autosuggest_start'
	zinit light zsh-users/zsh-autosuggestions

	# fzf-based tab completion UI (optional).
	if [ -f "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/features/fzf-tab.enabled" ]; then
		zinit ice lucid nocompile
		zinit light Aloxaf/fzf-tab
	fi

	# Auto-pair brackets, quotes, etc. — inserts closing ), ], }, ", ' automatically.
	zinit ice lucid nocompile
	zinit light hlissner/zsh-autopair

	# Syntax highlighting must be last because it wraps ZLE's self-insert widget.
	zinit ice lucid nocompile
	zinit light zdharma-continuum/fast-syntax-highlighting
}