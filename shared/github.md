---
managed-by: agents-bootstrap
source: shared/github.md
---

## GitHub CLI

Use sempre o GitHub CLI (`gh`) para interações com o GitHub. Nunca acesse
a API diretamente ou construa URLs manualmente.

### Criar issue

```bash
gh issue create --title "título" --body "descrição"
```

### Implementar uma issue

Antes de iniciar a implementação, consulte os detalhes da issue via CLI:

```bash
gh issue view <número>
```

Use o título, a descrição e os comentários da issue para guiar a implementação.

### Criar Pull Request

```bash
gh pr create --title "título" --body "$(cat <<'EOF'
## Resumo
- ...

## Plano de testes
- [ ] ...

EOF
)"
```

A PR deve ter a `develop` como base (`--base develop`).

### Trailer com a sessão do agente

O final do corpo da PR deve conter, como trailer, a sessão do agente que a gerou
(última linha do corpo, separada do texto por uma linha em branco), no padrão
`<agente>-session: <id>`, onde `<agente>` é o nome do agente em minúsculas
(indica onde recuperar o ID):

```text
<agente>-session: <id-da-sessao>
```

Exemplos: `claude-session: <id>`, `codex-session: <id>`, `opencode-session: <id>`.

Exemplo de corpo de PR:

```text
## Resumo
- adiciona geração de relatório

## Plano de testes
- [x] npm test

claude-session: 2467180b-b4fd-4294-be5f-41e9cbc3c40a
```

Regras do trailer:

- O prefixo identifica o agente que gerou a PR (ex.: `claude`, `codex`), para saber qual ferramenta usar para recuperar a sessão.
- Usar o ID real da sessão em andamento; nunca inventar ou deixar placeholder.
- No Claude Code, o ID é o nome do arquivo `.jsonl` mais recente da sessão em
  `~/.claude/projects/<diretorio-da-worktree>/` (permite retomar com `claude --resume <id>`).
  Em outros agentes, usar o identificador de sessão equivalente.
- Se não for possível determinar o ID, informar isso ao usuário em vez de omitir silenciosamente.
