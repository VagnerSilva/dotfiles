# Repository Guidelines

## Project Structure & Module Organization

This repository manages a portable Zsh environment and command-line tools. Root
files such as `.zshrc`, `.zshenv`, `.zprofile`, and `.zlogout` are the stowable
entry points. Keep application configuration under `.config/`: Zsh fragments
live in `.config/zsh/env/` and `.config/zsh/rc/`, with per-tool fragments in
`.config/zsh/rc/tools/`. Tool-specific assets include `.config/starship.toml`
and `.config/eza/theme.yml`.

Installation orchestration is in `install.sh`; reusable helpers are in
`setup/common.sh`; individual installers are in `setup/` and `setup/tools/`.
`uninstall.sh` reverses links and records created by the setup flow.

## Build, Test, and Development Commands

There is no build system or automated test suite. Use these checks before
submitting changes:

```bash
bash -n install.sh uninstall.sh setup/*.sh setup/tools/*.sh # Bash syntax
zsh -n .zshrc .zshenv .zprofile .zlogout                    # Zsh syntax
bash install.sh                                               # interactive installer
bash uninstall.sh                                             # remove managed links
```

Run the installer only in an intended test environment: it may install packages,
create symlinks, and change the login shell. Use `bash uninstall.sh --yes` only
when non-interactive cleanup is deliberate.

## Coding Style & Naming Conventions

Write setup scripts for Bash, beginning with `#!/usr/bin/env bash` and
`set -euo pipefail`. Follow the existing tab indentation in Bash functions,
quote variable expansions, prefer local variables inside functions, and reuse
helpers from `setup/common.sh` for logging, prompts, and package detection.

Name installer scripts with lowercase kebab case (`setup-nerd-font.sh`) and
tool fragments with lowercase names (`rc/tools/starship.zsh`). Add a new tool’s
shell initialization under `.config/zsh/rc/tools/` and source it through the
existing tool loader rather than expanding `.zshrc`.

## Testing Guidelines

For every script edit, run the matching syntax check above. For behavior
changes, exercise the smallest relevant installer manually in a disposable
environment and confirm both the success path and a safe decline at prompts.
Do not commit machine-specific paths, generated caches, credentials, or package
manager state.

## Commit & Pull Request Guidelines

Recent history uses concise Conventional Commit-style subjects, especially
`feat: ...` and `refactor: ...`. Use an imperative, scoped summary, for example
`fix: preserve existing zsh cache directory`. Keep each commit focused.

Pull requests should explain the user-visible setup change, list validation
commands and platforms tested, and call out any package installation, symlink,
or shell-profile impact. Include screenshots only when a visual terminal theme
or prompt change needs illustration.
