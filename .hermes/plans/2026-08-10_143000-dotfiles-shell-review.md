# Análise de Engenharia (Shell) — dotfiles

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Corrigir bugs reais, eliminar duplicação perigosa e fechar a lacuna de testes do shell do repositório de dotfiles.

**Architecture:** Repositório de dotfiles com instalador orquestrado por um CLI gerado (Bashly) — `bin/dotfiles` — cujos comandos (`install`/`uninstall`/`check`) disparam scripts em `setup/` e `setup/tools/`. Helpers compartilhados vivem em `setup/common.sh`. Symlinks criados via GNU stow; estado de "o que pertence a este projeto" registrado em `$XDG_STATE_HOME/dotfiles/owned-*`.

**Tech Stack:** Bash 4+ (POSIX-ish, com `[[ ]]` e arrays), GNU stow, Bashly (gerador de CLI), zsh (alvo). Sem suíte de testes automatizada hoje.

---

## 1. Pontos fortes (manter)

- Uso consistente de `set -euo pipefail` nos scripts de setup.
- Rastreamento de posse (`record_owned_path` / `record_owned_package`) e `--dry-run` no uninstall — raro e valioso.
- `confirm_step` com default seguro (`y/N`) e tratamento de EOF.
- Conformidade XDG em `common.sh` (CONFIG/CACHE/DATA/STATE).
- Backup de conflitos antes do stow (`backup_stow_conflicts`).
- Separação clara entre `setup/common.sh` e os instaladores individuais.

## 2. Achados (severidade)

### CRÍTICOS / BUGS

**C1 — Caminho de máquina hardcoded em `.zshrc` (viola AGENTS.md).**
`/home/vs/dotfiles/.zshrc:36` → `export PNPM_HOME="/home/vs/.local/share/pnpm"`.
Isso é específico de máquina e quebra em qualquer outro usuário/host. Deve ser `$HOME/.local/share/pnpm`. O bloco `# pnpm ... # pnpm end` foi quase certamente injetado por `pnpm setup` e commitado sem revisão. Também vale checar `setup/tools/*.sh` e `.config/zsh/env/paths.zsh` por outros `/home/vs/`.

**C2 — `uninstall --tools` remove pacotes pelo nome do comando, não do pacote (falha no apt).**
`setup/tools/packages.sh:86-88` grava `record_owned_package "$manager" "$package"` usando o *command name* (`fd`, `bat`), mas no Debian/Ubuntu o pacote é `fd-find` / `bat` (ver `install_names` em `packages.sh:63-72`). O uninstall (`src/uninstall_command.sh:106-125`, função `remove_owned_tools`) roda `sudo apt-get remove -y fd`, que falha (pacote inexistente). Corrigir registrando o `install_name`.

**C3 — `common.sh::install_packages` não tem caso `brew`, mas `detect_package_manager` pode retornar `brew`.**
`setup/common.sh:73-87` cobre `pkg/brew?NÃO/apt/dnf/yum/pacman/zypper/apk`. Porém `detect_package_manager` (common.sh:60-71) retorna `brew` no macOS. Resultado: em macOS, `ensure_packages` cai no `*)` "Unsupported package manager". O `setup-zsh.sh` (local, não compartilhado) TEM o caso `brew` — divergência. Centralizar no `common.sh`.

### MÉDIOS

**M1 — `is_termux` inconsistente entre arquivos.**
`common.sh:35-37` checa `TERMUX_VERSION` **ou** `PREFIX=/data/data/com.termux/files/usr`. `setup-zsh.sh:50-52` checa só `TERMUX_VERSION`, e `setup-nerd-font.sh:142` checa só `TERMUX_VERSION`/`~/.termux`. Mesma função com comportamentos diferentes = bug silencioso dependendo de qual script roda.

**M2 — Uso de string `"true"/"false"` como comando em uninstall.**
`src/uninstall_command.sh:28` `if "$ASSUME_YES"; then`, `:43` `if "$DRY_RUN"; then`, `:102` `if "$REMOVE_TOOLS"; then`. Funciona porque existem binários `true`/`false`, mas é frágil e confunde leitores/linters. Preferir `if [ "$ASSUME_YES" = true ]`.

**M3 — `confirm_step` / `log` / `warn` / `error` / `detect_package_manager` / `install_packages` DUPLICADOS.**
`setup-zsh.sh` e `setup-nerd-font.sh` redefinem tudo localmente em vez de `source`ar `common.sh`. Pior: `setup-zsh.sh` **não** dá `source` em `common.sh` — roda 100% standalone com cópias que já divergiram (C1, C3, M1). `setup-nerd-font.sh` também reimplementa `require_command`. Essa duplicação é o maior risco de manutenção do repo.

**M4 — `backup_file` (nerd-font) colide no mesmo segundo e orfana `.bak`.**
`setup-nerd-font.sh:100-104` → `cp -- "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"`. Se rodar 2x na mesma segunda, sobrescreve o backup anterior; além disso deixa arquivos `.bak.*` espalhados. Usar `mktemp`-style ou checar existência.

**M5 — atuin via installer oficial não é registrado como pacote próprio.**
`setup/tools/packages.sh:32-57` grava `owned-path` (`$HOME/.atuin`, `$HOME/.local/bin/atuin`) mas não `owned-package`. `uninstall --tools` não o remove. Inconsistência com o modelo de posse.

### LEVES / CHEIRO DE CÓDIGO

**L1 — Indentação inconsistente.** `setup-zsh.sh` e `setup-nerd-font.sh` usam 2 espaços; AGENTS.md manda tabs. Aplicar tabs no repo inteiro.

**L2 — Scripts não são "sourceable" para teste.** Todos chamam `main "$@"` incondicionalmente no fim. Para testes Bats, adicionar guarda:
```bash
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then main "$@"; fi
```

**L3 — `remove_stowed_links` deixa diretórios-pai vazios** (`~/.config/zsh`, etc.). Cosmético; pode limpar opcionalmente.

**L4 — `configure_json_terminal_settings` (vscode) insere por regex/string hacky** e pode corromper formatação ou duplicar chave se o JSON tiver múltiplas raízes/whitespace variável. Aceitável como best-effort, mas documentar risco e testar com fixture.

**L5 — `curl | sh` para atuin/fnm/sdkman.** Padrão comum, mas fnm/atuin já baixam para temp; sdkman e atuin fazem pipe direto. Recomendar baixar para temp e (onde houver) validar checksum antes de executar.

### LACUNA PRINCIPAL

**T0 — Nenhum teste automatizado** para scripts que rodam `rm -rf`, mudam shell de login e criam symlinks. AGENTS.md lista só checagens manuais (`bash -n`, smoke). Para shell *safety-critical*, recomendo **Bats** (`bats-core`) cobrindo: `common.sh` (detect/ensure/record), `uninstall` (dry-run não destrói, protege pacotes `git/zsh/stow`), e `packages.sh` (mapeamento command↔package).

---

## 3. Abordagem proposta

1. Corrigir primeiro o que quebra em outros ambientes (C1, C2, C3, M1) — baixo risco, alto valor.
2. Centralizar helpers em `common.sh` e fazer `setup-zsh.sh`/`setup-nerd-font.sh` darem `source` (M3) — elimina a fonte de divergência futura.
3. Endurecer `uninstall` (M2, M5) e `backup_file` (M4).
4. Adicionar suíte Bats (T0) + guarda de `main` (L2) + tabs (L1).
5. Documentar riscos (L4, L5) no README.

---

## 4. Plano passo a passo

### Task 1: Remover caminho hardcoded de máquina em `.zshrc`
**Files:** Modify `/home/vs/dotfiles/.zshrc:36`
**Step 1:** Trocar `export PNPM_HOME="/home/vs/.local/share/pnpm"` por:
```bash
export PNPM_HOME="$HOME/.local/share/pnpm"
```
**Step 2:** Buscar outros leaks de `/home/vs/` no repo:
Run: `grep -rn '/home/vs/' --include='*.sh' --include='*.zsh' --include='.zshrc' --include='.zshenv' .`
Expected: só a linha de PNPM (ou nenhuma após o fix).
**Step 3:** `zsh -n .zshrc` → sem erro.
**Step 4:** Commit:
```bash
git add .zshrc && git commit -m "fix: use \$HOME instead of hardcoded /home/vs in .zshrc"
```

### Task 2: Registrar nome de pacote correto (instalação x uninstall)
**Files:** Modify `/home/vs/dotfiles/setup/tools/packages.sh:59-89`
**Step 1:** Escrever teste Bats (ver Task 9) que garante `record_owned_package` recebe `install_name` (ex.: `fd-find` no apt).
**Step 2:** No loop de gravação (linhas 86-88), gravar o `install_name` mapeado:
```bash
for package in "${missing[@]}"; do
  # resolve install_name usado no install
  local rec="${package}"
  case "$package" in
    fd) [ "$manager" = apt ] && rec=fd-find ;;
    bat) [ "$manager" = apt ] && rec=bat ;;
  esac
  record_owned_package "$manager" "$rec"
done
```
**Step 3:** `bash -n setup/tools/packages.sh` → ok; rodar Bats da Task 9.
**Step 4:** Commit.

### Task 3: Adicionar caso `brew` em `common.sh::install_packages`
**Files:** Modify `/home/vs/dotfiles/setup/common.sh:73-87`
**Step 1:** Inserir antes do `*)`:
```bash
    brew) brew install "$@" ;;
```
**Step 2:** `bash -n setup/common.sh` → ok.
**Step 3:** Commit.

### Task 4: Unificar `is_termux` em `common.sh`
**Files:** Modify `/home/vs/dotfiles/setup-zsh.sh:50-52` e `/home/vs/dotfiles/setup-nerd-font.sh:142`
**Step 1:** Remover as cópias locais; garantir que ambos `source`m `common.sh` (ver Task 5) e usem a versão central (checa `TERMUX_VERSION` **ou** `PREFIX`).
**Step 2:** `bash -n` dos dois scripts → ok.
**Step 3:** Commit.

### Task 5: Fazer `setup-zsh.sh`/`setup-nerd-font.sh` usarem `common.sh`
**Files:** Modify `/home/vs/dotfiles/setup-zsh.sh` (todo), `/home/vs/dotfiles/setup-nerd-font.sh` (todo)
**Step 1:** No topo de cada um, após `set -euo pipefail`, adicionar:
```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
```
(note: `setup-nerd-font.sh` já tem `source` parcial — consolidar).
**Step 2:** Remover as redefinições locais de `log/warn/error/confirm_step/detect_package_manager/install_packages/require_command/is_termux`.
**Step 3:** `bash -n` dos dois e smoke: `bash -n setup-zsh.sh setup-nerd-font.sh`.
**Step 4:** Commit (`refactor: deduplicate helpers by sourcing common.sh`).

### Task 6: Endurecer flags booleanas no uninstall
**Files:** Modify `/home/vs/dotfiles/src/uninstall_command.sh:28,43,102`
**Step 1:** Trocar `if "$ASSUME_YES"; then` → `if [ "$ASSUME_YES" = true ]; then`; `if "$DRY_RUN"; then` → `if [ "$DRY_RUN" = true ]; then`; `if "$REMOVE_TOOLS"; then` → `if [ "$REMOVE_TOOLS" = true ]; then`.
**Step 2:** `bash -n src/uninstall_command.sh` → ok; smoke `bin/dotfiles uninstall --dry-run` não deve destruir nada.
**Step 3:** Commit.

### Task 7: Registrar atuin como pacote próprio e corrigir `backup_file`
**Files:** Modify `/home/vs/dotfiles/setup/tools/packages.sh:32-57`; `/home/vs/dotfiles/setup-nerd-font.sh:100-104`
**Step 1 (packages.sh):** Após o install oficial, adicionar `record_owned_package "atuin-official" atuin` (ou marcador) para que `--tools` saiba removê-lo (mesmo que a remoção seja `rm -rf "$HOME/.atuin"` — tratar no uninstall como owned-path, já coberto).
**Step 2 (nerd-font):** Substituir `backup_file` por versão segura:
```bash
backup_file() {
  local file="$1" bak
  [ -f "$file" ] || return 0
  bak="$(mktemp "${file}.bak.XXXXXX")"
  cp -- "$file" "$bak"
}
```
**Step 3:** `bash -n` dos dois.
**Step 4:** Commit.

### Task 8: Adicionar guarda `main` e normalizar tabs
**Files:** Modify todos os `setup/*.sh`, `setup/tools/*.sh`, `src/*_command.sh`
**Step 1:** Substituir `main "$@"` final por:
```bash
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then main "$@"; fi
```
**Step 2:** Reformatear `setup-zsh.sh` e `setup-nerd-font.sh` para tabs (AGENTS.md).
**Step 3:** `bash -n` em todos; `shfmt -l .` (se disponível) para confirmar.
**Step 4:** Commit.

### Task 9: Criar suíte de testes Bats
**Files:** Create `/home/vs/dotfiles/tests/common.bats`, `tests/uninstall.bats`, `tests/packages.bats`; add `tests/helpers.bash`
**Step 1 (common.bats):** Testar `detect_package_manager` (stub de `command -v`), `record_owned_path`/`record_owned_package` (grava e lê arquivo temporário), `ensure_packages` com manager fake.
**Step 2 (uninstall.bats):** Com `--dry-run`, `remove_path` NÃO executa `rm -rf` (use `touch` de canário); pacotes protegidos (`git|curl|zsh|stow`) não são removidos; `is_owned_link` reconhece só links apontando para `$SCRIPT_DIR`.
**Step 3 (packages.bats):** Garantir que o `install_name` de `fd` no apt seja `fd-find` e de `bat` seja `bat` (espec do Task 2).
**Step 4:** Instalar `bats` e rodar: `bats tests/` → todos verdes.
**Step 5:** Documentar em AGENTS.md a seção "Test" com `bats tests/`.
**Step 6:** Commit.

### Task 10: Documentar riscos de `curl|sh` e JSON terminal
**Files:** Modify `/home/vs/dotfiles/README.md` (seção de segurança/instaladores)
**Step 1:** Documentar que atuin/fnm/sdkman baixam e executam scripts remotos; recomendar validação de checksum onde houver release asset.
**Step 2:** Documentar que a configuração de fonte em VSCode/WTerminal é best-effort (pode não preservar formatação de `settings.json`).
**Step 3:** Commit.

---

## 5. Arquivos que mudam (resumo)
- `.zshrc` (C1)
- `setup/common.sh` (C3, M1, centralização)
- `setup-zsh.sh` (M1, M3, L1, L2)
- `setup-nerd-font.sh` (M1, M3, M4, L1, L2)
- `setup/tools/packages.sh` (C2, M5)
- `src/uninstall_command.sh` (M2)
- `src/*_command.sh` (L2)
- `tests/*.bats` (T0, novo)
- `README.md` / `AGENTS.md` (docs)

## 6. Validação
- `bash -n` em todos os `.sh` modificados.
- `bashly generate` se `bashly.yml` mudar (não neste plano).
- `bats tests/` → verde.
- `bin/dotfiles --help`, `bin/dotfiles check` smoke.
- `bin/dotfiles uninstall --dry-run` num sandbox: nenhum `rm` real; canários permanecem.

## 7. Riscos / trade-offs
- Centralizar helpers (M3) exige checar que `setup-zsh.sh` não dependia de diferenças das cópias locais — revisar diff com cuidado.
- Bats adiciona dependência de dev (`bats-core`); pode ser opcional no CI mas recomendado.
- Mudanças em uninstall devem ser testadas em ambiente descartável (rm -rf).

## 8. Perguntas em aberto
- Quer que eu implemente tudo (todas as tasks) ou só o subconjunto crítico (C1–C3, M1–M3)?
- Bats é aceitável como dependência de dev, ou prefere testes em shell puro (`shunit2`/`assert`)?
- O bloco pnpm em `.zshrc` deve ser mantido (com `$HOME`) ou removido por ser gerado por ferramenta?
