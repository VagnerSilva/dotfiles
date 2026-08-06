# Fluxo Stow deste repositório

## Aplicação

`setup-zsh.sh` implementa o layout em `apply_stow_layout`:

- exige `stow`, `.zshenv` e `.config/zsh`;
- executa a partir da raiz do repositório com `stow --target="$HOME" --restow
  --no-folding .`;
- ignora `.git`, `setup/`, `setup-*.sh`, `install.sh` e `uninstall.sh`;
- chama `backup_stow_conflicts` antes de aplicar os links.

`backup_stow_conflicts` percorre os arquivos de origem, calcula o caminho no
destino e mantém três exceções: destino inexistente, link cujo alvo resolve
para a mesma origem, e diretório real. Os demais arquivos são movidos para o
sufixo `.dotfiles-backup`.

## Reversão

`uninstall.sh` implementa `remove_stowed_links`:

- percorre arquivos e diretórios fora de `.git`, `setup/`, instaladores e o
  próprio desinstalador;
- só remove destino se `is_owned_link` confirmar que ele é simbólico e seu alvo
  resolvido começa com `SCRIPT_DIR/`;
- encaminha a remoção por `remove_path`, que apenas informa a ação em
  `--dry-run`.

O restante de `uninstall.sh` lida com recursos instalados e estado XDG; isso não
é parte de uma reversão normal de links. `--tools` pode remover pacotes
registrados e exige atenção separada.

## Cenários de teste

```bash
bash -n setup-zsh.sh uninstall.sh
bash uninstall.sh --dry-run
```

Para exercitar Stow sem tocar no diretório do usuário, use um diretório
temporário como destino e uma cópia descartável do repositório. Verifique:

1. link existente para a mesma origem não muda;
2. arquivo conflitante recebe backup, sem substituir backup existente;
3. diretório real é preservado;
4. link externo e arquivo normal não são removidos pela reversão;
5. link que aponta para este repositório é removido somente fora de `--dry-run`.
