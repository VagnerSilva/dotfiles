---
name: shell-installer-validation
description: Safely validate Bash installers and uninstallers in this dotfiles repository. Use when testing setup scripts, installer prompts, package or download branches, GNU Stow application, XDG isolation, idempotency, ownership tracking, dry-run cleanup, or regression behavior without modifying the user's real home directory or system packages.
---

# Validação segura de instaladores shell

Use esta skill para testar alterações em `install.sh`, `uninstall.sh`, `setup/`
e `setup/tools/`. Leia a [matriz de validação](references/validation-matrix.md)
e selecione o menor cenário que exercite a mudança.

## Isolamento obrigatório

1. Antes de executar qualquer instalador, crie um diretório temporário com
   `mktemp -d` e confirme que ele não é a raiz do repositório nem o `$HOME`
   real.
2. Defina `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME` e
   `XDG_STATE_HOME` dentro desse diretório. Mantenha o repositório como origem,
   não como destino de artefatos de teste.
3. Limpe apenas o diretório temporário criado e validado pelo teste. Preserve o
   log até avaliar o resultado.
4. Não use `sudo`, gerenciadores de pacotes, `chsh`, downloads de rede ou
   instaladores de terceiros num teste sem autorização explícita do usuário.

## Sequência de testes

- Execute `bash -n` nos scripts alterados e seus chamadores.
- Primeiro exercite a recusa em cada prompt: ela deve sair com sucesso, sem
  criar links, estado XDG ou chamadas externas inesperadas.
- Para Stow, responda apenas ao passo de aplicação em um HOME temporário;
  verifique links, arquivos de backup e a ausência de alterações fora do
  destino temporário.
- Execute o mesmo fluxo uma segunda vez para verificar idempotência. Não aceite
  duplicação de PATH, arquivos de estado ou links.
- Rode `bash uninstall.sh --dry-run` com o mesmo ambiente e verifique que ele
  lista somente recursos que pertencem ao teste. Só execute a reversão real no
  HOME temporário e após revisar o dry-run.

## Cobertura por risco

Teste o caminho já instalado, o recurso ausente, uma resposta negativa ao
prompt e uma falha previsível de pré-requisito. Para mudanças em ownership,
crie um arquivo ou link externo no destino temporário e confirme que a
remoção o preserva. Para mudanças em download ou pacote, valide as decisões e
mensagens com comandos ausentes ou stubs isolados; não contorne confirmação
com execução privilegiada.

## Relatório

Registre o comando, variáveis de isolamento, respostas de prompt, estado
observado e limpeza realizada. Diferencie validação de sintaxe, teste de fluxo
local e caminhos que continuam não exercitados por exigirem rede, privilégios
ou uma plataforma específica.
