---
name: external-tool-bootstrap-security
description: Safely review and modify external tool downloads, archives, Git clones, and vendor installers in this dotfiles repository. Use when changing curl usage, URLs, versions, architecture assets, checksums or signatures, temporary files, archive extraction, installer execution, post-install verification, or ownership tracking for Starship, FNM, SDKMAN, Atuin, Zinit, Nerd Fonts, or similar tools.
---

# Segurança de bootstrap externo

Use esta skill para qualquer fluxo que obtenha ou execute conteúdo externo.
Leia primeiro [o inventário de bootstraps](references/bootstrap-inventory.md) e
identifique a origem, a versão, o artefato esperado e o destino local.

## Revisão antes da mudança

1. Mantenha versão, URL e mapeamento de sistema/arquitetura explícitos. Para
   uma origem Git, prefira tag ou commit conhecido quando o fluxo exigir versão
   reproduzível; preserve atualizações `--ff-only` quando já suportadas.
2. Confirme HTTPS, falha em resposta HTTP, arquivo temporário privado e cleanup
   por `trap`. Não escreva no destino final antes de a obtenção terminar.
3. Se o fornecedor publicar checksum ou assinatura verificável, valide-o antes
   de extrair ou executar. Não invente hashes nem desative validação TLS para
   acomodar uma falha de rede.
4. Peça confirmação explícita antes de rede, execução de instalador externo,
   clone ou atualização Git, extração de arquivo, criação de links, ou escrita
   fora do repositório.

## Execução segura

- Prefira baixar um instalador em arquivo temporário e executá-lo com argumentos
  explícitos. Use um pipeline `curl | sh` somente quando a interface oficial
  não permitir alternativa e mantenha restrições HTTPS/TLS, ambiente isolado e
  confirmação específica.
- Para arquivos, extraia apenas em diretório temporário ou destino controlado,
  verifique o binário/arquivo esperado e suas permissões antes de registrá-lo.
  Não aceite sucesso apenas porque `tar` ou `curl` retornou zero.
- Isole alterações automáticas de configuração de shell com `ZDOTDIR`
  temporário. Preserve os arquivos stowados e integre a ferramenta pelo módulo
  Zsh apropriado.
- Registre caminho ou pacote em `owned-paths`/`owned-packages` somente depois da
  verificação pós-instalação. Não remova nem sobrescreva um recurso existente
  que não seja comprovadamente do projeto.

## Falhas e fallback

Use fallback de gerenciador de pacotes apenas após relatar por que a fonte
primária falhou e confirmar que a plataforma o suporta. Em falha, mantenha o
destino sem estado parcial, limpe temporários e informe URL, versão, asset e
pré-requisito ausente sem expor dados sensíveis.

## Validação

Execute `bash -n` no script alterado. Teste seleção de asset para plataformas
conhecidas e desconhecidas, ferramenta já instalada, download inválido e
artefato sem binário esperado. Não faça download real em testes sem autorização;
use respostas de recusa, arquivos temporários ou stubs isolados para comprovar
o controle de fluxo.
