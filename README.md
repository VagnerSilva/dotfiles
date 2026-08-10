# dotfiles

Portable Zsh environment and command-line tools, managed by the `dotfiles`
command-line interface (generated with [Bashly](https://bashly.dev/)).

## Usage

```text
dotfiles install     instala zsh, ferramentas, Zinit e Nerd Font
dotfiles uninstall   remove apenas recursos criados por este projeto
dotfiles check       verifica pré-requisitos e estado, sem alterar nada
dotfiles help        mostra a ajuda de um comando
```

Run `dotfiles` from this repository with `./bin/dotfiles`, or install it on
`~/.local/bin` through the final optional step of `dotfiles install`.

### Install

Interactive, guided flow in 5 steps: zsh/stow/login shell/dotfile links, CLI
tools (packages, starship, fnm, sdkman), Zinit, Nerd Font and terminal
configuration, and optionally the `dotfiles` CLI on `PATH`. Every step asks
for confirmation before making changes.

### Uninstall

Removes only resources this project created: stowed links and paths registered
in `$XDG_STATE_HOME/dotfiles/owned-paths`. System packages are never removed
unless you pass `--tools` (only packages recorded in `owned-packages`; `git`,
`curl`, `zsh` and `stow` are always protected).

```text
dotfiles uninstall [--dry-run] [--tools] [--yes]
```

- `--dry-run` shows what would be removed without changing anything.
- `--tools` also removes system packages recorded as installed by this project.
- `--yes` skips the confirmation prompt.

### Check

Read-only report of prerequisites, dotfile links, tools, extras (Nerd Font,
ownership state) and the login shell. Exits `0` when everything is ready and
`1` when something is missing. `--verbose` shows resolved paths.

## Compatibility wrappers

`install.sh` and `uninstall.sh` remain as thin wrappers that delegate to
`bin/dotfiles install` and `bin/dotfiles uninstall`, so existing commands such
as `bash uninstall.sh --yes` keep working.

## Development

The CLI is defined in `src/bashly.yml` with implementations in `src/`; the
executable is generated with:

```bash
bashly generate   # writes bin/dotfiles; never edit it by hand
```
