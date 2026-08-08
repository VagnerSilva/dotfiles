# Ordem de inicialização do Zsh

## Arquivos de entrada

1. `.zshenv` define `SHELL`, fixa `ZDOTDIR` em `$HOME`, define
   `ZSH_CONFIG_DIR` e carrega `env/xdg-zsh.zsh`.
2. `env/xdg-zsh.zsh` define `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`,
   `XDG_DATA_HOME`, `XDG_STATE_HOME` e garante o diretório de cache do Zsh sem
   depender de PATH.
3. `.zprofile` evita carga dupla com `_ZPROFILE_SOURCED`; então carrega, nesta
   ordem, `env/paths.zsh`, `env/general.zsh`, `env/programs.zsh` e
   `env/sdkman.zsh`.
4. `.zshrc` carrega `.zprofile` quando a sessão interativa não é login e, em
   seguida, `rc/options.zsh`, `rc/aliases.zsh`, `rc/history.zsh`,
   `rc/zinit.zsh`, `rc/completion.zsh` e `rc/tools.zsh`. Por fim, chama
   `load_zle_plugins` se a função existir.

## Dependências de plugins e completion

- `rc/zinit.zsh` exige `$ZINIT_HOME/zinit.zsh`; se ele faltar, reporta a ação
  necessária e retorna.
- Os plugins de completion são carregados por Zinit antes de `compinit`.
- `rc/completion.zsh` prepara `fpath`, usa um dump XDG, chama `compinit` e
  executa `zinit cdreplay -q` se Zinit estiver disponível.
- Plugins que dependem de ZLE são carregados por `load_zle_plugins` após o
  carregamento de completion.

## Localização de mudanças

| Necessidade | Local |
| --- | --- |
| XDG, diretórios fundamentais | `env/xdg-zsh.zsh` |
| PATH e `fpath` | `env/paths.zsh` |
| Variáveis de runtime e ferramentas de linha de comando | `env/programs.zsh` |
| Ambiente de uma ferramenta de login | `env/<ferramenta>.zsh` |
| Alias, histórico, opções, completion | `rc/*.zsh` correspondente |
| Integração interativa de ferramenta | `rc/tools/<ferramenta>.zsh` |

## Checagens úteis

```bash
zsh -n .zshenv .zprofile .zshrc .config/zsh/env/*.zsh .config/zsh/rc/*.zsh
zsh -lic 'print -r -- "$ZDOTDIR|$ZSH_CONFIG_DIR|$XDG_CACHE_HOME"'
zsh -ic 'whence -v zinit; whence -v compinit'
```

As duas últimas checagens usam a configuração real do usuário e podem gerar
cache. Execute-as somente quando esse efeito for aceitável.
