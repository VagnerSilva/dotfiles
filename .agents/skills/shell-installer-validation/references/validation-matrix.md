# Matriz de validação do repositório

## Ambiente isolado

Use um diretório temporário somente para o teste e exporte os caminhos antes de
executar o script alvo:

```bash
sandbox_dir="$(mktemp -d)"
export HOME="$sandbox_dir/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME"
```

Não execute `rm -rf` com um caminho construído sem primeiro confirmar que ele
começa no diretório temporário criado pelo teste.

## Cenários mínimos

| Alteração | Evidência mínima |
| --- | --- |
| Sintaxe Bash | `bash -n` no script e chamador afetado |
| Prompt opcional | resposta vazia ou `n`; nenhuma ação externa |
| Stow | aplicar em HOME temporário, depois repetir |
| Ownership e remoção | `uninstall.sh --dry-run`, depois reversão no sandbox |
| Caminhos XDG | arquivos e estado aparecem apenas sob os XDG temporários |
| Ferramenta já presente | segunda execução não baixa, instala ou registra duplicado |
| Plataforma ausente | falha clara, sem arquivo parcial ou remoção |

## Limites de cada fluxo

- `setup-zsh.sh` usa `$HOME` como destino Stow e contém passos independentes
  para instalar Zsh/Stow, mudar shell e aplicar links. Recuse os três primeiros
  passos e autorize somente Stow no sandbox quando esse for o alvo do teste.
- `setup/tools/*.sh`, `setup-zinit.sh` e `setup-nerd-font.sh` podem usar rede,
  pacote ou arquivos de configuração. Teste primeiro seus caminhos de recusa e
  pré-requisitos; só exercite instalação real com autorização explícita.
- `uninstall.sh --dry-run` não remove nada. `--tools` introduz remoção de
  pacotes e não deve ser usado em uma validação local comum.

## Checagens do repositório

```bash
bash -n install.sh uninstall.sh setup/*.sh setup/tools/*.sh
zsh -n .zshenv .zprofile .zshrc .zlogout
bash uninstall.sh --dry-run
```

O último comando deve usar o mesmo ambiente HOME/XDG temporário ao verificar
uma alteração na reversão.
