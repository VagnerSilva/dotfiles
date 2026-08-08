---
name: bashly-cli-ux
description: Design, improve, or gradually migrate Bash command-line interfaces in this dotfiles repository using Bashly. Use when creating the dotfiles CLI, defining Bashly commands, arguments or flags, generating help and validation, versioning a generated Bashly executable, preserving install.sh or uninstall.sh wrappers, or improving CLI usability without changing installer safety behavior.
---

# UX de CLI com Bashly

Use esta skill para evoluir a interface de linha de comando deste repositório.
Leia primeiro [a referência de migração](references/bashly-migration.md).

## Contrato da CLI

A interface pública alvo é `dotfiles` com quatro subcomandos explícitos:

- `dotfiles install`
- `dotfiles uninstall`
- `dotfiles check`
- `dotfiles help`

Use `--verbose` como flag global apenas para ampliar logs. Defina `--dry-run`
somente em comandos cuja semântica pode ser demonstrada sem efeito permanente;
não o anuncie como segurança para operações que ainda baixam, instalam ou mudam
o shell. Preserve confirmações explícitas para rede, pacotes, Stow, `chsh` e
remoções, mesmo quando a CLI já tiver validado argumentos.

## Migração gradual

1. Mapeie um entry point atual para um único subcomando e mantenha sua lógica
   em Bash manual; Bashly deve cuidar apenas de parsing, validação e help.
2. Defina a interface em `src/bashly.yml` e mantenha implementações em `src/`.
   Gere e versione o executável final em `bin/dotfiles`; nunca edite esse
   arquivo manualmente.
3. Migre um subcomando por vez. Enquanto a equivalência não estiver validada,
   mantenha `install.sh` e `uninstall.sh` como wrappers compatíveis que delegam
   a `bin/dotfiles install` e `bin/dotfiles uninstall` somente quando seguro.
4. Não altere comportamento, prompts, ownership ou defaults de segurança apenas
   para acomodar o modelo de comandos Bashly.

## Design da interface

Dê a cada comando uma frase de ajuda orientada à ação e exemplos executáveis.
Use argumentos posicionais somente quando a ordem for inequívoca; use flags
nomeadas para opções, validação e modos de risco. Rejeite combinações inválidas
no YAML, incluindo flags conflitantes. Mantenha comandos sem efeitos externos
(`check`, `help`) separados de fluxos interativos de instalação ou limpeza.

Use o ambiente de desenvolvimento para gerar a CLI e confira que qualquer
alteração em `src/bashly.yml` venha acompanhada da atualização esperada em
`bin/dotfiles`. Não instale Bashly, Ruby ou dependências nem gere artefatos sem
solicitação explícita do usuário.

## Validação

Quando Bashly estiver disponível, execute `bashly generate` e `bash -n
bin/dotfiles`. Teste `--help`, `help`, comando inválido, flags inválidas e cada
subcomando migrado. Use HOME/XDG temporários para `install` e `uninstall` e
mantenha os wrappers como casos de compatibilidade. Relate separadamente o que
foi validado por parsing da CLI e o que exigiria operações externas.
