---
name: zsh-environment-diagnostics
description: Diagnose and safely modify Zsh startup, environment, PATH, XDG/ZDOTDIR, module, plugin, completion, and cache behavior in this dotfiles repository. Use when login and interactive shells differ, a command is missing from PATH, a Zsh module does not load, completion fails, plugins start in the wrong order, or shell startup becomes slow or unreliable.
---

# Diagnóstico do ambiente Zsh

Use esta skill para investigar ou alterar o carregamento do Zsh neste
repositório. Leia primeiro [a ordem de inicialização](references/startup-order.md).

## Diagnóstico

1. Reproduza no menor modo aplicável: `zsh -l`, `zsh -i`, ou sessão não
   interativa. Registre `ZDOTDIR`, `ZSH_CONFIG_DIR`, variáveis XDG, `PATH` e a
   presença do comando ou módulo afetado.
2. Determine em que etapa a configuração deveria carregar: `.zshenv` para
   ambiente essencial; `.zprofile` para login; `.zshrc` para interação;
   `env/*.zsh` para ambiente; `rc/*.zsh` para comportamento interativo.
3. Confirme o arquivo carregador e os pré-requisitos antes de alterar um
   módulo. Não corrija uma falha de ambiente duplicando exports na `.zshrc`.
4. Para plugins e completion, preserve a sequência Zinit → plugins de
   completion → `compinit`/`cdreplay` → plugins ZLE.

## Regras de alteração

- Mantenha `.zshenv` mínima, segura sem PATH e aplicável a toda sessão. Use
  `.zprofile` para ambiente de login e `.zshrc` apenas para recursos
  interativos.
- Centralize caminhos XDG em `env/xdg-zsh.zsh`; use `ZSH_CONFIG_DIR` para
  localizar módulos. Não introduza caminhos específicos da máquina ou exports
  duplicados.
- Altere `PATH` em `env/paths.zsh` ou `env/programs.zsh`, preserve a ordem e a
  deduplicação por `typeset -U path`, e só adicione diretórios existentes quando
  isso for a convenção do módulo.
- Carregue integrações de ferramentas em `rc/tools/<ferramenta>.zsh`; o
  despachante `rc/tools.zsh` as carrega por glob com qualificador `(N)`.
- Não instale, atualize ou baixe plugins durante a inicialização do shell.
  Encaminhe isso para os scripts em `setup/`.

## Cache e recuperação

Trate `zcompdump`, `.zwc` e caches de ferramentas como dados descartáveis, mas
peça confirmação antes de removê-los. Diferencie cache obsoleto de erro de
ordem de carregamento. Não use `compinit -C` para ocultar um `fpath` inválido;
regenerar o dump e revisar o `fpath` são verificações separadas.

## Validação

Execute `zsh -n` nos arquivos alterados. Faça uma sessão de login e uma sessão
interativa isoladas, verificando valores de ambiente, disponibilidade de
comandos e ausência de erro de sourcing. Após mudanças em plugins ou
completion, valide carregamento do `compinit`, `zinit cdreplay` e inicialização
ZLE sem forçar atualizações de plugins.
