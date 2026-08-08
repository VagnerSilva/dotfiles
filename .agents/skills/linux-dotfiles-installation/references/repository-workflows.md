# Mapa dos fluxos do repositório

## Orquestração

- `install.sh` executa, nesta ordem: `setup-zsh.sh`, `setup/tools.sh`,
  `setup-zinit.sh` e `setup-nerd-font.sh`.
- `setup/tools.sh` executa `packages.sh`, `starship.sh`, `fnm.sh` e
  `sdkman.sh`.
- `setup/common.sh` concentra defaults XDG, logging, confirmação, detecção de
  Termux/gerenciador de pacotes e registro de recursos gerenciados.

## Instalação e estado

- O suporte atual de pacotes é `pkg`, `apt`, `dnf`, `yum`, `pacman`, `zypper`,
  `apk` e `brew`; esta skill cobre Linux e Termux, não adiciona regras novas
  para Homebrew.
- Recursos instalados fora do gerenciador devem ser anotados em
  `$XDG_STATE_HOME/dotfiles/owned-paths`; pacotes instalados pelo projeto, em
  `owned-packages` como `gerenciador:pacote`.
- O setup do Zsh usa GNU Stow com destino `$HOME`, cria backup de conflitos e
  oferece separadamente instalação de Zsh, Stow, alteração do shell e links.
- Ferramentas podem baixar instaladores externos. Atuin usa `ZDOTDIR`
  temporário para impedir edição da configuração stowada; Starship seleciona
  artefato por sistema/arquitetura; FNM e SDKMAN usam diretórios XDG ou do
  usuário configuráveis.

## Reversão

- `uninstall.sh` remove links que apontam para este repositório e itens do
  estado registrado. Por padrão preserva pacotes; `--tools` tenta remover
  apenas pacotes registrados, exceto `git`, `curl`, `zsh` e `stow`.
- Use `bash uninstall.sh --dry-run` para analisar o que seria removido. Nunca
  assuma que `--yes` ou `--tools` são seguros sem confirmação explícita.

## Backlog de skills

- Concluída: `stow-dotfiles-recovery`, para aplicação e reversão segura de
  links, conflitos, backups e ownership.
- Concluída: `zsh-environment-diagnostics`, para ordem de carregamento,
  XDG/ZDOTDIR, PATH, cache, plugins e módulos do Zsh.
- Concluída: `terminal-font-integration`, para Nerd Fonts e configuração
  segura de terminais GNOME, Konsole, XFCE, Termux e WSL.

O backlog inicial de skills do repositório está concluído.

## Checagens locais

```bash
bash -n install.sh uninstall.sh setup/*.sh setup/tools/*.sh
zsh -n .zshrc .zshenv .zprofile .zlogout
bash uninstall.sh --dry-run
```
