# Inventário de bootstrap externo

| Componente | Fluxo atual | Verificação após instalação |
| --- | --- | --- |
| Starship | asset GitHub por versão, SO e arquitetura; fallback para pacote | binário em PATH ou `$HOME/.local/bin/starship` |
| FNM | baixa instalador de `fnm.vercel.app` e executa com diretório explícito | `$FNM_INSTALL_DIR/fnm` executável |
| SDKMAN | baixa `get.sdkman.io` e executa com `SDKMAN_DIR` | `bin/sdkman-init.sh` existe |
| Atuin | pacote primeiro; fallback para instalador oficial em `ZDOTDIR` temporário | `$HOME/.atuin/bin/atuin` executável e link local |
| Zinit | clone Git HTTPS ou `git pull --ff-only` | `$ZINIT_HOME/zinit.zsh` existe |
| Nerd Fonts | dois TTFs fixados por versão no repositório upstream | Regular e Bold instaladas com modo `0644` |

## Padrões existentes

- Scripts usam `set -euo pipefail`, `mktemp`/`mktemp -d` e `trap` para limpeza.
- Starship seleciona asset em `starship_asset`; plataforma não suportada requer
  override explícito `STARSHIP_ASSET`.
- Atuin isola a modificação automática de `.zshrc` com `ZDOTDIR` temporário.
- Cada fluxo confirma o binário, entrada ou arquivo esperado antes de chamar
  `record_owned_path` ou `record_owned_package`.

## Pontos de atenção

- Um instalador oficial pode alterar shell, PATH ou arquivos no HOME; trate isso
  como efeito externo mesmo se o script for baixado por HTTPS.
- Um arquivo de release não deve ser considerado confiável apenas pelo nome do
  asset; use mecanismo de integridade publicado pela origem quando houver.
- `uninstall.sh` só pode remover recursos registrados como pertencentes ao
  projeto. Um registro prematuro transforma uma falha parcial em risco de
  remoção indevida.

## Checagens locais

```bash
bash -n setup-zinit.sh setup-nerd-font.sh setup/tools/*.sh
```

Exercite branches de plataforma e arquivo ausente sem rede. Uma execução real
de download, instalação ou atualização requer confirmação separada.
