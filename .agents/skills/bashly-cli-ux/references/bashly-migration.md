# Migração gradual para Bashly

## Layout padrão

```text
src/
├── bashly.yml          # contrato declarativo da CLI
└── ...                 # implementações manuais dos comandos
bin/
└── dotfiles            # executável Bashly gerado e versionado
```

Bashly gera o parser, valida argumentos e flags, produz tela de ajuda e combina
a configuração YAML com as funções em `src/`. O conteúdo gerado é derivado;
altere `src/bashly.yml` e as funções, regenere e versiona o resultado em vez de
editar `bin/dotfiles` diretamente.

## Interface deste repositório

| Subcomando | Responsabilidade | Compatibilidade |
| --- | --- | --- |
| `install` | orquestrar setup Zsh, ferramentas, Zinit e fonte | destino de `install.sh` |
| `uninstall` | remover somente recursos gerenciados | destino de `uninstall.sh` |
| `check` | verificar pré-requisitos e estado sem mudança | novo, sem efeitos externos |
| `help` | exibir ajuda do comando ou subcomando | equivalente a `--help` |

`--verbose` pode ser global. Flags de risco, como `--tools`, `--yes` e
`--dry-run`, pertencem apenas ao subcomando cuja semântica já existe. Não
promova `--yes` a uma autorização global.

## Ordem de migração

1. Criar o contrato e o help sem alterar o comportamento dos scripts atuais.
2. Migrar `check`, pois ele é somente leitura.
3. Migrar `uninstall`, preservando `--dry-run`, ownership e confirmação.
4. Migrar `install` em etapas, mantendo seus prompts e integrações externas.
5. Converter `install.sh` e `uninstall.sh` em wrappers somente após validar
   equivalência de cada caminho público.

## Geração e testes

```bash
bashly generate
bash -n bin/dotfiles
bin/dotfiles --help
bin/dotfiles help
bin/dotfiles invalid-command
```

Testar `install` e `uninstall` em HOME/XDG temporários com a skill
`shell-installer-validation`. Versionar `src/` e `bin/dotfiles` na mesma
alteração.

## Documentação oficial

- https://bashly.dev/usage/getting-started/
- https://bashly.dev/configuration/command/
- https://bashly.dev/configuration/flag/
- https://bashly.dev/usage/settings/
