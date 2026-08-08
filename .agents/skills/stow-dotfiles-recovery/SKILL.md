---
name: stow-dotfiles-recovery
description: Diagnose, apply, and safely reverse GNU Stow dotfile links in this repository. Use when resolving Stow conflicts, inspecting symlink ownership, backing up existing dotfiles, applying the stow layout, recovering a failed link operation, or changing uninstall behavior without deleting user-owned files.
---

# Recuperação segura de dotfiles com Stow

Use esta skill para operações de links de dotfiles neste repositório. Leia
[os detalhes do fluxo Stow](references/stow-workflow.md) antes de alterar
`setup-zsh.sh` ou `uninstall.sh`.

## Diagnóstico antes de alteração

1. Confirme a origem do repositório, o destino de Stow e a disponibilidade de
   `stow` e `readlink`.
2. Faça um inventário somente leitura dos arquivos de origem, links existentes
   e conflitos no destino. Diferencie arquivo regular, diretório, link válido e
   link quebrado.
3. Determine propriedade resolvendo o link: ele só pertence ao projeto quando
   o alvo resolvido começa no diretório deste repositório.
4. Para remoção, execute primeiro `bash uninstall.sh --dry-run` e revise cada
   caminho listado. Nunca infira propriedade pelo nome ou localização.

## Aplicar e recuperar links

Peça confirmação explícita antes de executar GNU Stow, mover backups, remover
links ou alterar arquivos no diretório-alvo. Preserve o layout atual: execute
Stow a partir da raiz do repositório, use `--target="$HOME"`, `--restow` e
`--no-folding`, e ignore `.git`, `setup/`, instaladores e `uninstall.sh`.

Antes de substituir um conflito, mantenha links que já apontam para a mesma
origem e ignore diretórios reais. Para arquivos conflitantes, crie ou preserve
um backup explícito; não sobrescreva silenciosamente um backup existente.
Pare e reporte se o conflito não puder ser classificado com segurança.

## Reversão segura

Remova apenas links simbólicos cujo alvo resolvido esteja dentro da raiz do
repositório. Preserve arquivos, diretórios e links externos. Remoções de
ferramentas, fontes, caches ou pacotes seguem as regras de ownership em
`$XDG_STATE_HOME/dotfiles`; não amplie uma reversão de links para esses recursos
sem solicitação explícita.

Mantenha `--dry-run` sem efeitos e `--yes` apenas como dispensa do prompt, não
como autorização implícita para `--tools`. Nunca remova `git`, `curl`, `zsh` ou
`stow` pelo desinstalador.

## Validação

Após editar scripts, execute `bash -n setup-zsh.sh uninstall.sh`. Para alterar
reversão, valide `bash uninstall.sh --dry-run`; para alterar Stow, use um
diretório temporário como destino e confirme que links válidos permanecem,
conflitos recebem backup e arquivos não pertencentes são preservados. Não rode
o instalador contra `$HOME` sem autorização do usuário.
