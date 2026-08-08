---
name: linux-dotfiles-installation
description: Diagnose and safely modify the Linux or Termux installation flows in this dotfiles repository. Use when changing Bash installers, package-manager support, external tool downloads, XDG paths, installation idempotency, ownership tracking, or prompts and safeguards around package installation, Stow, shell changes, and cleanup.
---

# Instalação segura de dotfiles Linux

Use esta skill para mudanças nos instaladores deste repositório. Leia primeiro
[o mapa dos fluxos](references/repository-workflows.md) e os arquivos afetados.

## Fluxo de trabalho

1. Identifique o menor script responsável e os efeitos externos envolvidos.
2. Faça pré-checagens somente leitura: plataforma, comandos necessários,
   caminhos XDG, estado atual do recurso e suporte do gerenciador de pacotes.
3. Preserve o comportamento idempotente: recurso já instalado ou configurado
   deve encerrar com sucesso sem criar duplicação nem baixar novamente.
4. Faça a menor alteração coerente e mantenha `set -euo pipefail`, variáveis
   locais, expansões entre aspas e mensagens `log`, `warn` e `error`.
5. Execute a validação proporcional e informe comandos executados, plataforma
   coberta e operações que não foram exercitadas.

## Limites de segurança

Peça confirmação explícita do usuário antes de executar qualquer ação que use
rede, `sudo`, gerenciador de pacotes, `chsh`, GNU Stow, `rm`, `mv`, `ln`, ou
modifique arquivos fora do repositório. Não trate uma checagem prévia bem-
sucedida como autorização para instalar, atualizar, remover ou alterar o shell.

Antes de adicionar uma remoção, confirme a propriedade do caminho. Preserve
arquivos não registrados em `owned-paths` e pacotes não registrados em
`owned-packages`. Nunca remova dependências protegidas (`git`, `curl`, `zsh`,
`stow`) pelo fluxo de limpeza.

## Regras de implementação

- Centralize detecção de plataforma e instalação de pacotes em
  `setup/common.sh`; mantenha suporte a `apt`, `dnf`, `yum`, `pacman`, `zypper`,
  `apk` e `pkg` (Termux).
- Use os defaults `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME` e
  `XDG_STATE_HOME`; não introduza caminhos absolutos específicos da máquina.
- Isole instaladores de terceiros que alterem configuração de shell usando um
  `ZDOTDIR` temporário quando necessário. Prefira downloads HTTPS e falhe com
  mensagem clara se o artefato ou binário esperado não existir.
- Registre somente recursos criados pelo projeto com `record_owned_path` ou
  `record_owned_package`, para que `uninstall.sh` possa revertê-los.
- Mantenha perguntas com default seguro (`[y/N]`) e uma saída explícita para
  operações opcionais ou plataformas não suportadas.

## Validação

Execute `bash -n` no script alterado e em seus chamadores afetados. Para uma
mudança de comportamento, valide o caminho já instalado, a recusa do prompt e
o erro previsível (comando, plataforma ou arquivo ausente), sem rodar ações
externas sem autorização. Use `bash uninstall.sh --dry-run` para inspecionar a
reversão; só use `--tools` ou `--yes` quando o usuário autorizar expressamente.
