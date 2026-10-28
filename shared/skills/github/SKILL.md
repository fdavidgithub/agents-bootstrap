---
name: github
description: Use em qualquer interação com o GitHub — criar ou consultar issues, abrir Pull Request — via GitHub CLI (gh), incluindo o trailer obrigatório com a sessão do agente no corpo da issue e da PR.
managed-by: agents-bootstrap
source: shared/skills/github/SKILL.md
---

# github

Use sempre o GitHub CLI (`gh`) para interagir com o GitHub. Nunca acesse a API
diretamente nem construa URLs manualmente.

## Criar issue

```bash
gh issue create --title "título" --body "$(cat <<'EOF'
descrição

<agente>-session: <id-da-sessao>
EOF
)"
```

O corpo da issue termina com o trailer da sessão do agente (ver abaixo).

## Implementar uma issue

Antes de iniciar a implementação, consulte os detalhes da issue:

```bash
gh issue view <número>
```

Use o título, a descrição e os comentários para guiar a implementação.

## Criar Pull Request

```bash
gh pr create --base develop --title "título" --body "$(cat <<'EOF'
## Resumo
- ...

## Plano de testes
- [ ] ...

<agente>-session: <id-da-sessao>
EOF
)"
```

A PR tem a `develop` como base (`--base develop`) e termina com o trailer da
sessão do agente.

## Trailer com a sessão do agente

O final do corpo da PR **e da issue** contém, como trailer, a sessão do agente
que a gerou: última linha do corpo, separada do texto por uma linha em branco,
no padrão `<agente>-session: <id>`, com `<agente>` em minúsculas.

Exemplos de prefixo: `claude-session`, `codex-session`, `opencode-session`.

Exemplo de corpo de PR:

```text
## Resumo
- adiciona geração de relatório

## Plano de testes
- [x] npm test

claude-session: 2467180b-b4fd-4294-be5f-41e9cbc3c40a
```

Regras:

-   O prefixo identifica o agente que gerou a PR ou a issue, indicando qual
    ferramenta usar para recuperar a sessão.
-   Use o ID real da sessão em andamento; nunca invente nem deixe placeholder.
-   No Claude Code, o ID é o nome do arquivo `.jsonl` mais recente da sessão em
    `~/.claude/projects/<diretorio-da-worktree>/` (permite retomar com
    `claude --resume <id>`). Em outros agentes, use o identificador de sessão
    equivalente.
-   Se não for possível determinar o ID, informe isso ao usuário em vez de
    omitir silenciosamente.
