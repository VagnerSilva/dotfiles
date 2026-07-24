# dotfiles

## Diagnóstico de `Bus error`

Durante a instalação, habilite o rastreamento de inicialização quando solicitado.
Cada novo terminal registra um relatório em
`$XDG_STATE_HOME/zsh/debug/startup-*.log`. Se um job receber `SIGBUS`, o
relatório registra o status e os jobs ativos sem interferir no fzf-tab.

Para capturar também o processo e o sinal `SIGBUS` com `strace`, execute:

	bash debug-zsh-bus-error.sh

Use normalmente o terminal de diagnóstico até o erro aparecer e execute `exit`.
O script informa o diretório em `$XDG_STATE_HOME/zsh/debug` com os arquivos
`strace.<pid>`. Envie esse diretório para análise; ele registra os
comandos de inicialização e pode conter caminhos do ambiente local.