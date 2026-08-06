# Fluxo de fontes do repositório

## Fonte e estado

`setup-nerd-font.sh` usa Meslo por padrão:

- `NERD_FONT_NAME=Meslo`;
- `NERD_FONT_VERSION=v3.2.1`;
- arquivos Regular e Bold em `$XDG_DATA_HOME/fonts/NerdFonts/$FONT_NAME`;
- diretório registrado em `owned-paths` apenas depois do download;
- `fc-cache -f "$XDG_DATA_HOME/fonts"` quando `fc-cache` existe;
- família obtida com `fc-scan`, com fallback `MesloLGS Nerd Font`.

A presença de ambos os arquivos de fonte evita novo download. O download usa
arquivos temporários, `curl -fL` e `install -m 0644`.

## Integrações suportadas

| Ambiente | Destino | Comportamento atual |
| --- | --- | --- |
| GNOME Terminal | perfil padrão por `gsettings` | define fonte e desativa fonte do sistema |
| Konsole | primeiro `~/.local/share/konsole/*.profile` | cria backup e altera `Font=` |
| XFCE Terminal | `~/.config/xfce4/terminal/terminalrc` | cria backup e altera `FontName=` |
| Termux | `~/.termux/font.ttf` | copia a fonte e chama reload se disponível |
| VS Code / Code OSS | `settings.json` XDG | cria backup e define `terminal.integrated.fontFamily` |
| Windows Terminal / VS Code no Windows | settings via WSL | atualiza JSON e, se possível, instala/registra a fonte |

As integrações são opcionais e só são chamadas depois da confirmação em
`configure_detected_terminals`.

## Recuperação e validação

- Perfis de Konsole, XFCE e JSON recebem backup datado por `backup_file` antes
  de alteração. Confirme o arquivo de backup e a validade do JSON após mudar.
- `uninstall.sh` remove a fonte somente se o caminho estiver registrado como
  criado pelo projeto; não restaura automaticamente perfis de terminal.
- A primeira verificação é `bash -n setup-nerd-font.sh`. Depois, use
  `fc-scan --format '%{family}\n' <arquivo-da-fonte>` quando disponível e
  confirme visualmente os glifos no terminal alvo.
