---
name: terminal-font-integration
description: Diagnose and safely modify Nerd Font installation and terminal font configuration in this dotfiles repository. Use when changing setup-nerd-font.sh, font download or cache behavior, font discovery, or GNOME Terminal, Konsole, XFCE Terminal, Termux, VS Code, Windows Terminal, and WSL font integration.
---

# Integração segura de fontes de terminal

Use esta skill para mudanças de Nerd Fonts e perfis de terminal. Leia primeiro
[o fluxo de fontes](references/font-workflow.md) e identifique a plataforma e o
terminal realmente presentes antes de propor uma alteração.

## Diagnóstico e instalação

1. Verifique `NERD_FONT_NAME`, `NERD_FONT_VERSION`, `FONT_DIR`, os arquivos de
   fonte esperados e a família detectada por `fc-scan`, quando disponível.
2. Diferencie fonte ausente, cache de fontes desatualizado e perfil de terminal
   que ainda aponta para outra família. Não baixe novamente quando Regular e
   Bold já estão instaladas.
3. Peça confirmação explícita antes de baixar, instalar arquivos em diretórios
   do usuário, executar `fc-cache`, alterar configurações do terminal ou
   interagir com Windows/WSL.
4. Registre o diretório de fonte apenas se tiver sido criado pelo projeto, para
   que a remoção condicional em `uninstall.sh` preserve fontes do usuário.

## Configuração por terminal

Aplique somente ao terminal detectado e preserve a configuração existente:

- GNOME Terminal: descubra o perfil padrão por `gsettings` antes de alterar
  `use-system-font` e `font`.
- Konsole e XFCE Terminal: crie backup datado antes de editar o arquivo de
  perfil; atualize ou acrescente apenas a chave de fonte aplicável.
- Termux: use `$HOME/.termux/font.ttf`, somente após confirmar Termux e uma
  fonte de origem válida; recarregue configurações apenas se o comando existir.
- VS Code, Code OSS e Windows Terminal: valide que o JSON existe e é legível,
  preserve conteúdo/JSON válido e faça backup antes da escrita. No WSL, valide
  `cmd.exe`, `wslpath` e PowerShell antes de executar qualquer operação Windows.

Não crie arquivos de configuração de terminal ausentes sem uma decisão explícita
do usuário. Sempre deixe uma falha de integração isolada: fonte instalada e
cache atualizado não devem falhar porque um terminal opcional não existe.

## Regras de implementação

- Mantenha downloads HTTPS, temporários via `mktemp`, permissões `0644` e
  validação de arquivos antes de instalá-los.
- Preserve `FONT_FAMILY` configurável e use a descoberta como fallback; não
  codifique a família detectada na configuração Zsh ou Starship.
- Separe download, atualização de cache, descoberta e configuração de terminal
  em funções independentes com logs e avisos claros.
- Não altere a inicialização Starship para resolver glifos ausentes: confirme
  primeiro a instalação e a seleção da Nerd Font no emulador de terminal.

## Validação

Execute `bash -n setup-nerd-font.sh`. Exercite detecção e caminhos ausentes sem
download; para uma integração real, use um perfil de teste ou backup verificável
e confirme que a família resultante aparece no terminal. Não execute o setup
contra configurações pessoais ou Windows sem autorização explícita.
